import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'line_state.dart';

const int _kMaxChartPoints = 5000;

class LineView extends StatefulWidget {
  final Dataset dataset;
  final LineState state;
  const LineView({super.key, required this.dataset, required this.state});

  @override
  State<LineView> createState() => _LineViewState();
}

class _LineViewState extends State<LineView> {
  List<ChartPoint> _allPoints = [];
  List<ChartPoint> _displayPoints = [];
  bool _isSampled = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant LineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.dataset != widget.dataset) {
      _prepareData();
    }
  }

  void _prepareData() {
    final columnName = widget.state.columnName;
    if (columnName == null) {
      _allPoints = [];
      _displayPoints = [];
      _isSampled = false;
      return;
    }

    final column = widget.dataset.numeric(columnName);
    final points = <ChartPoint>[];
    for (int i = 0; i < column.data.length; i++) {
      final y = column.data[i];
      if (y != null) points.add(ChartPoint(i.toDouble(), y));
    }

    _allPoints = points;
    _isSampled = _allPoints.length > _kMaxChartPoints;
    _displayPoints = _isSampled ? _allPoints.sample(_kMaxChartPoints) : _allPoints;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.columnName == null) {
      return const Center(child: Text("Выберите колонку для оси Y"));
    }
    if (_allPoints.isEmpty) {
      return const Center(child: Text("Нет данных для отображения"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSampled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Показано ${_displayPoints.length} из ${_allPoints.length} точек (сэмплирование)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            trackballBehavior: TrackballBehavior(
              enable: widget.state.trackballEnabled,
              activationMode: ActivationMode.singleTap,
              tooltipSettings: const InteractiveTooltip(format: 'point.y'),
            ),
            tooltipBehavior: TooltipBehavior(enable: true, duration: 2500),
            primaryXAxis: NumericAxis(
              title: const AxisTitle(text: 'Индекс'),
              majorGridLines: widget.state.showGridLines
                  ? const MajorGridLines(width: 1)
                  : const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: widget.state.columnName!),
              majorGridLines: widget.state.showGridLines
                  ? const MajorGridLines(width: 1)
                  : const MajorGridLines(width: 0),
            ),
            series: _buildSeries(context, _displayPoints),
          ),
        ),
      ],
    );
  }

  List<CartesianSeries> _buildSeries(BuildContext context, List<ChartPoint> points) {
    final color = Theme.of(context).colorScheme.primary;
    final markerSettings = MarkerSettings(
      isVisible: widget.state.showMarkers,
      width: widget.state.markerSize,
      height: widget.state.markerSize,
      borderColor: color,
    );
    final dataLabelSettings = DataLabelSettings(isVisible: widget.state.showDataLabels);
    final trendlines = widget.state.showTrendline
        ? [Trendline(type: TrendlineType.linear, color: Colors.orange)]
        : null;

    if (widget.state.lineType == LineType.curved) {
      return [
        SplineSeries<ChartPoint, double>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          color: color,
          width: widget.state.lineWidth,
          dashArray: widget.state.isDashed ? const [5, 3] : null,
          markerSettings: markerSettings,
          dataLabelSettings: dataLabelSettings,
          enableTooltip: true,
          animationDuration: widget.state.animationEnabled ? 1500 : 0,
          trendlines: trendlines,
        ),
      ];
    } else {
      return [
        LineSeries<ChartPoint, double>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          color: color,
          width: widget.state.lineWidth,
          dashArray: widget.state.isDashed ? const [5, 3] : null,
          markerSettings: markerSettings,
          dataLabelSettings: dataLabelSettings,
          enableTooltip: true,
          animationDuration: widget.state.animationEnabled ? 1500 : 0,
          trendlines: trendlines,
        ),
      ];
    }
  }
}

class ChartPoint {
  final double x;
  final double y;
  ChartPoint(this.x, this.y);
}