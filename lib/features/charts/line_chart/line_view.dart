import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'line_state.dart';

const int _kMaxChartPoints = 5000;

/// {@template line_view}
/// Виджет для отображения линейного графика
/// 
/// Использует SyncFusion Charts для построения интерактивного линейного графика
/// с поддержкой:
/// - Отображения трендов и временных рядов
/// - Маркеров на точках данных
/// - Сглаживания линии
/// - Всплывающих подсказок
/// - Сетки для удобства чтения
/// - Сэмплирования для больших наборов данных
/// 
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
    final allPoints = <ChartPoint>[];

    for (int i = 0; i < column.data.length; i++) {
      final yValue = column.data[i];
      if (yValue != null) {
        allPoints.add(ChartPoint(i.toDouble(), yValue));
      }
    }

    // Проверка наличия данных
    if (allPoints.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }

    // Сэмплирование для ускорения рендеринга на больших датасетах
    final points = allPoints.length > _kMaxChartPoints
        ? allPoints.sample(_kMaxChartPoints)
        : allPoints;
    final isSampled = points.length != allPoints.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSampled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Показано ${points.length} из ${allPoints.length} точек (сэмплирование)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            trackballBehavior: TrackballBehavior(
              enable: state.trackballEnabled,
              activationMode: ActivationMode.singleTap,
              tooltipSettings: const InteractiveTooltip(format: 'point.y'),
            ),
            tooltipBehavior: TooltipBehavior(enable: true, duration: 2500),
            primaryXAxis: NumericAxis(
              title: const AxisTitle(text: 'Индекс'),
              majorGridLines: state.showGridLines
                  ? const MajorGridLines(width: 1)
                  : const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: column.name),
              majorGridLines: state.showGridLines
                  ? const MajorGridLines(width: 1)
                  : const MajorGridLines(width: 0),
            ),
            series: _buildSeries(context, points),
          ),
        ),
      ],
    );
  }

  /// Строит серии данных для графика в зависимости от настроек
  /// Поддерживает разные типы линий, маркеры, пунктир и тренды
  /// Принимает на вход подготовленные точки данных и возвращает список серий для отображения
  /// 
  /// Принимает:
  /// - [context] — контекст для доступа к теме и цветам
  /// - [points] — список точек данных для построения графика
  /// 
  /// Возвращает список серий, который может содержать LineSeries, SplineSeries или StepLineSeries в зависимости от настроек
  List<CartesianSeries> _buildSeries(BuildContext context, List<ChartPoint> points) {
    final color = Theme.of(context).colorScheme.primary;

    if (state.lineType == LineType.curved) {
      return [
        SplineSeries<ChartPoint, double>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          color: color,
          width: state.lineWidth,
          dashArray: state.isDashed ? const [5, 3] : null,
          markerSettings: MarkerSettings(
            isVisible: state.showMarkers,
            width: state.markerSize,
            height: state.markerSize,
            borderColor: color,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: state.showDataLabels,
          ),
          enableTooltip: true,
          animationDuration: state.animationEnabled ? 1500 : 0,
          trendlines: state.showTrendline
              ? [Trendline(type: TrendlineType.linear, color: Colors.orange)]
              : null,
        ),
      ];
    }

    // По умолчанию — LineSeries
    return [
      LineSeries<ChartPoint, double>(
        dataSource: points,
        xValueMapper: (p, _) => p.x,
        yValueMapper: (p, _) => p.y,
        color: color,
        width: state.lineWidth,
        dashArray: state.isDashed ? const [5, 3] : null,
        markerSettings: MarkerSettings(
          isVisible: state.showMarkers,
          width: state.markerSize,
          height: state.markerSize,
          borderColor: color,
        ),
        dataLabelSettings: DataLabelSettings(isVisible: state.showDataLabels),
        enableTooltip: true,
        animationDuration: state.animationEnabled ? 1500 : 0,
        trendlines: state.showTrendline
            ? [Trendline(type: TrendlineType.linear, color: Colors.orange)]
            : null,
      ),
    ];
  }
}

/// Вспомогательный класс для хранения точки данных
class ChartPoint {
  final double x;
  final double y;

  ChartPoint(this.x, this.y);
}