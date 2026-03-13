import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'bar_state.dart';

/// {@template bar_view}
/// Виджет для отображения столбчатой диаграммы
/// 
/// Использует SyncFusion Charts для построения интерактивной столбчатой диаграммы
/// с поддержкой:
/// - Отображения распределения категориальных данных
/// - Подписей значений на столбцах
/// - Настраиваемой ширины столбцов
/// {@endtemplate}
class BarView extends StatelessWidget {
  final Dataset dataset;
  final BarState state;

  const BarView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state.columnName == null) {
      return const Center(
        child: Text("Выберите колонку"),
      );
    }

    final column = dataset.numeric(state.columnName!);
    final values = column.data.whereType<double>().toList();

    if (values.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }

    // Создаем категории (индексы) и значения
    final List<BarData> barData = [];
    for (int i = 0; i < values.length; i++) {
      barData.add(BarData('${i + 1}', values[i]));
    }

    // Преобразуем выравнивание
    final barAlignment = _getBarAlignment(state.alignment);

    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 2000,
        header: column.name,
        activationMode: ActivationMode.singleTap,
        format: 'Категория: point.x\nЗначение: point.y',
      ),

      primaryXAxis: CategoryAxis(
        title: const AxisTitle(text: 'Категория'),
        labelRotation: 45,
      ),
      
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: column.name),
      ),

      series: <BarSeries<BarData, String>>[
        BarSeries<BarData, String>(
          dataSource: barData,
          xValueMapper: (BarData data, _) => data.category,
          yValueMapper: (BarData data, _) => data.value,
          enableTooltip: true,
          width: state.barWidth,
          spacing: 0.2,
          color: Colors.blue,
          dataLabelSettings: DataLabelSettings(
            alignment: barAlignment,
            isVisible: state.showValues,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  // Преобразование BarAlignment в ChartAlignment
  ChartAlignment _getBarAlignment(BarAlignment alignment) {
    switch (alignment) {
      case BarAlignment.far:
        return ChartAlignment.far;
      case BarAlignment.near:
        return ChartAlignment.near;
      case BarAlignment.center:
        return ChartAlignment.center;
    }
  }
}

/// Вспомогательный класс для данных столбчатой диаграммы
class BarData {
  final String category;
  final double value;

  BarData(this.category, this.value);
}