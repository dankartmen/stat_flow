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

    // Расчет интервала между корзинами
    final interval = (max - min) / state.bins;

    return SfCartesianChart(
      
      crosshairBehavior: CrosshairBehavior(enable: true, lineDashArray: [20, 10], hideDelay: 300),
      // plotAreaBackgroundImage: AssetImage('assets/zzz_angel1.png'),
      // Настройка всплывающих подсказок
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 2000,
        header: column.name,
        activationMode: ActivationMode.singleTap,
      ),

      // Настройка осей
      primaryXAxis: NumericAxis(),
      primaryYAxis: NumericAxis(),

      // Серия данных - гистограмма
      series: <HistogramSeries<double, double>>[
        HistogramSeries<double, double>(
          dataSource: values,
          yValueMapper: (v, _) => v,
          binInterval: interval,
          enableTooltip: true,
          dataLabelSettings: DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }
}