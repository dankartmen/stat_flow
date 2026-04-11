import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'line_state.dart';

/// Максимальное количество точек, отображаемых на графике.
/// При превышении выполняется сэмплирование.
const int _kMaxChartPoints = 5000;

/// {@template line_view}
/// Виджет для отображения линейного графика (обычного или сглаженного).
///
/// Поддерживает:
/// - Отображение числового ряда по индексу или по времени
/// - Сглаженные кривые (Spline) или прямые линии
/// - Маркеры, подписи данных, сетку, трекболл
/// - Трендовую линию (линейную регрессию)
/// - Анимацию появления
/// - Сэмплирование для больших наборов данных (>5000 точек)
/// {@endtemplate}
class LineView extends StatefulWidget {
  /// Датасет c данныvb.
  final Dataset dataset;

  /// Состояние графика.
  final LineState state;

  /// {@macro line_view}
  const LineView({super.key, required this.dataset, required this.state});

  @override
  State<LineView> createState() => _LineViewState();
}

class _LineViewState extends State<LineView> {
  /// Все точки после загрузки (без сэмплирования).
  List<ChartPoint> _allPoints = [];

  /// Точки, отображаемые в данный момент (с учётом сэмплирования).
  List<ChartPoint> _displayPoints = [];

  /// Флаг, указывающий, что данные были сэмплированы.
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

  /// Подготавливает данные для отображения.
  ///
  /// Извлекает числовую колонку, создаёт точки с индексом в качестве X,
  /// применяет сэмплирование при необходимости.
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
    final theme = Theme.of(context);
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
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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

  /// Строит список серий для графика в зависимости от типа линии.
  List<CartesianSeries> _buildSeries(BuildContext context, List<ChartPoint> points) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final markerSettings = MarkerSettings(
      isVisible: widget.state.showMarkers,
      width: widget.state.markerSize,
      height: widget.state.markerSize,
      borderColor: color,
    );
    final dataLabelSettings = DataLabelSettings(isVisible: widget.state.showDataLabels);
    final trendlines = widget.state.showTrendline
        ? [Trendline(type: TrendlineType.linear, color: theme.colorScheme.secondary)]
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


/// Вспомогательный класс для хранения точки данных
class ChartPoint {
  final double x;
  final double y;

  ChartPoint(this.x, this.y);
}