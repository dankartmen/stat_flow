import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'line_state.dart';

/// {@template line_view}
/// Виджет для отображения линейного графика
/// 
/// Использует SyncFusion Charts для построения интерактивного линейного графика
/// с поддержкой:
/// - Отображения трендов и временных рядов
/// - Маркеров на точках данных
/// - Сглаживания линии
/// - Всплывающих подсказок
/// {@endtemplate}
class LineView extends StatelessWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние линейного графика с настройками
  final LineState state;

  /// {@macro line_view}
  const LineView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Проверка выбора колонки
    if (state.columnName == null) {
      return const Center(
        child: Text("Выберите колонку для оси Y"),
      );
    }

    // Получение числовой колонки
    final column = dataset.numeric(state.columnName!);

    // Фильтрация null-значений и подготовка точек
    final List<ChartPoint> points = [];
    
    for (int i = 0; i < column.data.length; i++) {
      final yValue = column.data[i];
      if (yValue != null) {
        points.add(ChartPoint(i.toDouble(), yValue));
      }
    }

    // Проверка наличия данных
    if (points.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }

    return SfCartesianChart(
      // Настройка всплывающих подсказок
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 2000,
        header: column.name,
        activationMode: ActivationMode.singleTap,
        format: 'Индекс: point.x\nЗначение: point.y',
      ),

      // Настройка осей
      primaryXAxis: NumericAxis(
        title: const AxisTitle(text: 'Индекс'),
        majorGridLines: state.showGridLines 
            ? const MajorGridLines(width: 1, color: Colors.grey)
            : const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: column.name),
        majorGridLines: state.showGridLines 
            ? const MajorGridLines(width: 1, color: Colors.grey)
            : const MajorGridLines(width: 0),
      ),

      // Серия данных - линейный график
      series: <LineSeries<ChartPoint, double>>[
        LineSeries<ChartPoint, double>(
          dataSource: points,
          xValueMapper: (ChartPoint point, _) => point.x,
          yValueMapper: (ChartPoint point, _) => point.y,
          enableTooltip: true,
          markerSettings: MarkerSettings(
            isVisible: state.showMarkers,
            shape: DataMarkerType.circle,
            width: 6,
            height: 6,
          ),
          color: Colors.blue,
          width: 2,
        ),
      ],
    );
  }
}

/// Вспомогательный класс для хранения точки данных
class ChartPoint {
  final double x;
  final double y;

  ChartPoint(this.x, this.y);
}