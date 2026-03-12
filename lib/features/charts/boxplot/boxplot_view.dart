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

    return SfCartesianChart(
      // Настройка оси X как категориальной (для одной колонки)
      primaryXAxis: CategoryAxis(),

      // Серия данных - ящик с усами
      series: <BoxAndWhiskerSeries<List<double>, String>>[
        BoxAndWhiskerSeries<List<double>, String>(
          dataSource: [values],
          xValueMapper: (_, __) => state.columnName!,
          yValueMapper: (v, _) => v,
          showMean: true, // Отображать среднее значение
        ),
      ],
    );
  }
}