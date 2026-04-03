import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'histogram_state.dart';

/// {@template histogram_view}
/// Виджет для отображения гистограммы распределения данных
/// 
/// Использует SyncFusion Charts для построения интерактивной гистограммы
/// с поддержкой:
/// - Автоматического расчета интервалов на основе количества корзин
/// - Всплывающих подсказок (tooltips) при нажатии на столбец
/// - Адаптивного отображения под разные размеры
/// 
/// Требует выбранную числовую колонку в [HistogramState].
/// {@endtemplate}
class HistogramView extends StatelessWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние гистограммы с настройками
  final HistogramState state;

  /// {@macro histogram_view}
  const HistogramView({
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

    // Расчет минимального и максимального значения
    final min = column.min() ?? values.first;
    final max = column.max() ?? values.first;

    // Приоритет: если пользователь задал binInterval — используем его,
    // иначе рассчитываем по количеству корзин
    final binInterval = state.binInterval ?? (max - min) / state.bins;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,

      crosshairBehavior: CrosshairBehavior(enable: true, lineDashArray: [8, 4]),
      // Настройка всплывающих подсказок
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 2500,
        header: column.name,
        activationMode: ActivationMode.singleTap,
      ),

      // Настройка осей
      primaryXAxis: NumericAxis(
        labelStyle: const TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(fontSize: 12),
      ),

      // Серия данных - гистограмма
      series: <HistogramSeries<double, double>>[
        HistogramSeries<double, double>(
          dataSource: values,
          yValueMapper: (v, _) => v,
          binInterval: binInterval,
          borderWidth: state.borderWidth,
          borderColor: Theme.of(context).colorScheme.primary,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          showNormalDistributionCurve: state.showNormalDistributionCurve,
          curveColor: Theme.of(context).colorScheme.secondary,
          curveWidth: 2.0,
          enableTooltip: true,
          dataLabelSettings: DataLabelSettings(
            isVisible: state.showDataLabels,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
        ),
      ],
    );
  }
}