import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'scatter_state.dart';

const int _kMaxChartPoints = 5000;

/// {@template scatter_view}
/// Виджет для отображения диаграммы рассеяния (scatter plot)
/// 
/// Использует SyncFusion Charts для построения интерактивного scatter plot
/// с поддержкой:
/// - Отображения зависимости между двумя числовыми колонками
/// - Всплывающих подсказок (tooltips) с координатами точки
/// - Адаптивного отображения под разные размеры
/// 
/// Требует две выбранные числовые колонки в [ScatterState].
/// {@endtemplate}
class ScatterView extends StatefulWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние диаграммы рассеяния с настройками
  final ScatterState state;
  /// {@macro scatter_view}
  const ScatterView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<ScatterView> createState() => _ScatterViewState();
}

class _ScatterViewState extends State<ScatterView> {
  /// Все точки для отображения на scatter plot
  late List<_ScatterPoint> _allPoints;
  /// Флаг, указывающий, были ли данные сэмплированы для производительности
  bool _isSampled = false;
  /// Точки, которые фактически отображаются (возможно сэмплированные)
  List<_ScatterPoint> _displayPoints = [];

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant ScatterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.firstColumnName != widget.state.firstColumnName ||
        oldWidget.state.secondColumnName != widget.state.secondColumnName ||
        oldWidget.dataset != widget.dataset) {
      _prepareData();
    }
  }

  /// Подготавливает данные для отображения на scatter plot
  /// - Извлекает выбранные колонки из датасета
  /// - Формирует список точек (x, y) для отображения
  /// - Выполняет сэмплирование, если количество точек превышает порог для производительности
  /// 
  /// Принимает:
  /// - [widget.state.firstColumnName] — имя первой числовой колонки (ось X)
  /// - [widget.state.secondColumnName] — имя второй числовой колонки (ось Y)
  /// - [widget.dataset] — датасет с данными для анализа
  /// 
  /// Возвращает:
  /// - Подготовленные данные для отображения на scatter plot
  void _prepareData() {
    log("Подготовка данных для scatter plot...");
    final firstColumnName = widget.state.firstColumnName;
    final secondColumnName = widget.state.secondColumnName;
    if (firstColumnName == null || secondColumnName == null) {
      _allPoints = [];
      _displayPoints = [];
      _isSampled = false;
      return;
    }

    final firstColumn = widget.dataset.numeric(firstColumnName);
    final secondColumn = widget.dataset.numeric(secondColumnName);
    log("Построение scatter plot для колонок: ${firstColumn.name} и ${secondColumn.name}");

    final minLength = firstColumn.data.length < secondColumn.data.length
        ? firstColumn.data.length
        : secondColumn.data.length;
    final allPoints = <_ScatterPoint>[];
    for (int i = 0; i < minLength; i++) {
      final x = firstColumn.data[i];
      final y = secondColumn.data[i];
      if (x != null && y != null) {
        allPoints.add(_ScatterPoint(x, y));
      }
    }

    _allPoints = allPoints;
    _isSampled = _allPoints.length > _kMaxChartPoints;
    _displayPoints = _isSampled
        ? _allPoints.sample(_kMaxChartPoints)
        : _allPoints;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.state.firstColumnName == null || widget.state.secondColumnName == null) {
      return const Center(child: Text("Выберите колонки для осей X и Y"));
    }
    if (_allPoints.isEmpty) {
      return const Center(child: Text("Нет данных для отображения"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSampled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Показано ${_displayPoints.length} из ${_allPoints.length} точек (сэмплирование)',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            // Настройка всплывающих подсказок
            tooltipBehavior: TooltipBehavior(
              enable: true,
              duration: 2000,
              header: '${widget.state.firstColumnName} vs ${widget.state.secondColumnName}',
              activationMode: ActivationMode.singleTap,
              format: 'X: point.x\nY: point.y',
            ),

            // Настройка осей
            primaryXAxis: NumericAxis(
              title: AxisTitle(text: widget.state.firstColumnName),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: widget.state.secondColumnName),
            ),

            // Серия данных - scatter plot
            series: <ScatterSeries<_ScatterPoint, double>>[
              ScatterSeries<_ScatterPoint, double>(
                dataSource: _displayPoints,
                xValueMapper: (_ScatterPoint point, _) => point.x,
                yValueMapper: (_ScatterPoint point, _) => point.y,
                enableTooltip: true,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  shape: DataMarkerType.circle,
                  width: 8,
                  height: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// {@template scatter_point}
/// Вспомогательный класс для хранения точки данных диаграммы рассеяния
/// {@endtemplate}
class _ScatterPoint {
  /// Координата X
  final double x;

  /// Координата Y
  final double y;

  /// {@macro scatter_point}
  _ScatterPoint(this.x, this.y);
}