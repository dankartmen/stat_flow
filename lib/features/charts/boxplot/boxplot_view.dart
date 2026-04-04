import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'boxplot_state.dart';

/// {@template boxplot_view}
/// Виджет для отображения ящика с усами (box plot)
/// 
/// Использует SyncFusion Charts для построения интерактивного ящика с усами
/// с поддержкой:
/// - Автоматического расчета статистик (медиана, квартили, выбросы)
/// - Отображения среднего значения на графике
/// - Адаптивного отображения под разные размеры
/// - Настройки визуального стиля (ширина, цвет, отступы)
/// - Сэмплирования для больших наборов данных
/// 
/// Требует выбранную числовую колонку в [BoxPlotState].
/// {@endtemplate}
class BoxPlotView extends StatelessWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние ящика с усами с настройками
  final BoxPlotState state;

  /// {@macro boxplot_view}
  const BoxPlotView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Проверка выбора колонки
    if (state.columnName == null) {
      return const Center(
        child: Text("Выберите колонку"),
      );
    }

    // Получение числовой колонки
    final column = dataset.numeric(state.columnName!);

    // Фильтрация null-значений
    final values = column.data
        .whereType<double>()
        .toList();

    // Проверка наличия данных
    if (values.isEmpty) {
      return const Center(
        child: Text("Нет данных"),
      );
    }

    final maxPoints = state.maxPoints <= 0 ? values.length : state.maxPoints;
    final displayValues = values.length > maxPoints
        ? values.sample(maxPoints)
        : values;
    final isSampled = displayValues.length != values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSampled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Показано ${displayValues.length} из ${values.length} точек (сэмплирование)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            // Настройка оси X как категориальной (для одной колонки)
            primaryXAxis: CategoryAxis(
              title: const AxisTitle(text: 'Поле'),
            ),
            primaryYAxis: NumericAxis(
              title: const AxisTitle(text: 'Значение'),
            ),
            // Серия данных - ящик с усами
            series: <BoxAndWhiskerSeries<List<double>, String>>[
              BoxAndWhiskerSeries<List<double>, String>(
                dataSource: [displayValues],
                xValueMapper: (_, __) => state.columnName!,
                yValueMapper: (v, _) => v,
                boxPlotMode: state.boxPlotMode,
                width: state.boxWidth,
                spacing: state.spacing,
                borderWidth: state.borderWidth,
                borderColor: Theme.of(context).colorScheme.primary,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                showMean: state.showMean,
                markerSettings: MarkerSettings(
                  isVisible: state.showOutliers,
                  width: state.outlierSize,
                  height: state.outlierSize,
                  shape: DataMarkerType.circle,
                  borderColor: Theme.of(context).colorScheme.error,
                ),
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}