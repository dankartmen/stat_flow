import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'histogram_data_calculator.dart';
import 'histogram_models.dart';
import 'histogram_state.dart';

/// {@template histogram_view}
/// Виджет для отображения гистограммы распределения числовых данных.
/// 
/// Использует SyncFusion Charts для построения интерактивной гистограммы
/// с поддержкой:
/// - Автоматического или ручного задания количества интервалов (bins)
/// - Разбиения по категориальной колонке (несколько серий)
/// - Отображения кривой нормального распределения
/// - Подписей значений на столбцах
/// - Тултипов и кроссхейра
/// 
/// Требует выбранную числовую колонку в [HistogramState].
/// {@endtemplate}
class HistogramView extends StatefulWidget {
  /// Датасет с данными для отображения.
  final Dataset dataset;

  /// Состояние гистограммы с настройками.
  final HistogramState state;

  /// {@macro histogram_view}
  const HistogramView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<HistogramView> createState() => _HistogramViewState();
}

/// Состояние виджета [HistogramView].
/// Отвечает за подготовку данных и построение графика.
class _HistogramViewState extends State<HistogramView> {
  /// Данные для отображения в виде списка серий.
  late List<HistogramSeriesData> _seriesData;

  /// Флаг, указывающий, что данные были сэмплированы.
  late bool _isSampled;

  /// Общее количество точек в выбранной колонке (до сэмплирования).
  late int _totalCount;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant HistogramView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пересчитываем данные при изменении ключевых параметров
    if (oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.state.splitByColumn != widget.state.splitByColumn ||
        oldWidget.dataset != widget.dataset ||
        oldWidget.state.bins != widget.state.bins ||
        oldWidget.state.binInterval != widget.state.binInterval) {
      _prepareData();
    }
  }

  /// Подготавливает данные для отображения.
  /// 
  /// Вызывает [HistogramDataCalculator.calculate] и обновляет состояние.
  void _prepareData() {
    final result = HistogramDataCalculator.calculate(
      dataset: widget.dataset,
      state: widget.state,
    );
    setState(() {
      _seriesData = result.seriesData;
      _isSampled = result.isSampled;
      _totalCount = result.totalCount;
    });
  }

  /// Вычисляет интервал между бинами, если он не задан явно.
  /// 
  /// Принимает:
  /// - [seriesData] — список серий данных
  /// - [bins] — количество интервалов
  /// 
  /// Возвращает:
  /// - вычисленный интервал (max - min) / bins
  /// - 1.0, если данные пусты
  double _calculateBinInterval() {
    double binInterval = widget.state.binInterval ?? 0;
    if (binInterval <= 0) {
      final allValues = _seriesData.expand((s) => s.values).toList();
      if (allValues.isNotEmpty) {
        final min = allValues.reduce((a, b) => a < b ? a : b);
        final max = allValues.reduce((a, b) => a > b ? a : b);
        binInterval = (max - min) / widget.state.bins;
      } else {
        binInterval = 1.0;
      }
    }
    return binInterval;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Проверка выбора колонки
    if (widget.state.columnName == null) {
      return const Center(child: Text("Выберите колонку"));
    }
    if (_seriesData.isEmpty || _seriesData.every((s) => s.values.isEmpty)) {
      return const Center(child: Text("Нет данных"));
    }

    final binInterval = _calculateBinInterval();

    return Column(
      children: [
        // Информация о сэмплировании
        if (_isSampled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Показано сэмплированных данных',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: Legend(
              isVisible: _seriesData.length > 1,
              position: LegendPosition.top,
            ),
            crosshairBehavior: CrosshairBehavior(
              enable: true,
              lineDashArray: const [8, 4],
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              duration: 2500,
              header: widget.state.columnName,
              activationMode: ActivationMode.singleTap,
            ),
            primaryXAxis: NumericAxis(
              title: AxisTitle(text: widget.state.columnName),
            ),
            primaryYAxis: NumericAxis(
              title: const AxisTitle(text: 'Частота'),
            ),
            series: _buildSeries(theme, binInterval),
          ),
        ),
      ],
    );
  }

  /// Строит список серий для отображения на диаграмме.
  ///
  /// Принимает:
  /// - [theme] — текущая тема для получения цветов
  /// - [binInterval] — интервал между бинами
  ///
  /// Возвращает:
  /// - список серий [HistogramSeries]
  List<CartesianSeries> _buildSeries(ThemeData theme, double binInterval) {
    final colors = Colors.primaries;
    final seriesList = <CartesianSeries>[];

    for (int i = 0; i < _seriesData.length; i++) {
      final seriesData = _seriesData[i];
      final color = colors[i % colors.length];

      seriesList.add(
        HistogramSeries<double, double>(
          dataSource: seriesData.values,
          yValueMapper: (v, _) => v,
          binInterval: binInterval,
          name: seriesData.groupName,
          color: color.withValues(alpha: 0.7),
          borderColor: color,
          borderWidth: widget.state.borderWidth,
          showNormalDistributionCurve: widget.state.showNormalDistributionCurve,
          curveColor: theme.colorScheme.secondary,
          curveWidth: 2.0,
          enableTooltip: true,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.state.showDataLabels,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
          opacity: 0.7,
        ),
      );
    }
    return seriesList;
  }
}