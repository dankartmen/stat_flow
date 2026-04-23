import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'boxplot_data_calculator.dart';
import 'boxplot_models.dart';
import 'boxplot_state.dart';

/// {@template boxplot_view}
/// Виджет для отображения ящика с усами (box plot)
/// 
/// Использует SyncFusion Charts для построения интерактивного ящика с усами
/// с поддержкой:
/// - Автоматического расчета статистик (медиана, квартили, выбросы)
/// - Отображения среднего значения на графике
/// - Адаптивного отображения под разные размеры
/// - Настройки визуального стиля (ширина, цвет, отступы)
/// - Сэмплирования для больших наборов данных
/// 
/// Требует выбранную числовую колонку в [BoxPlotState].
/// {@endtemplate}
class BoxPlotView extends StatefulWidget {
  /// Датасет с данными для отображения.
  final Dataset dataset;

  /// Состояние ящика с усами с настройками.
  final BoxPlotState state;

  /// {@macro boxplot_view}
  const BoxPlotView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<BoxPlotView> createState() => _BoxPlotViewState();
}

/// Состояние виджета [BoxPlotView].
/// Отвечает за подготовку данных и построение графика.
class _BoxPlotViewState extends State<BoxPlotView> {
  /// Все значения для отображения на ящике с усами (одна или несколько групп).
  late List<BoxPlotSeriesData> _seriesData;

  /// Флаг, указывающий, были ли данные сэмплированы для производительности.
  late bool _isSampled;

  /// Общее количество точек в выбранной колонке (до сэмплирования).
  late int _totalCount;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant BoxPlotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пересчитываем данные при изменении ключевых параметров
    if (oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.state.groupByColumn != widget.state.groupByColumn ||
        oldWidget.state.maxPoints != widget.state.maxPoints ||
        oldWidget.dataset != widget.dataset) {
      _prepareData();
    }
  }

  /// Подготавливает данные для отображения.
  /// 
  /// - Извлекает числовые значения из выбранной колонки.
  /// - Если задана группировка, разбивает данные по категориям.
  /// - Выполняет сэмплирование, если количество точек превышает порог [maxPoints].
  void _prepareData() {
    final result = BoxPlotDataCalculator.calculate(
      dataset: widget.dataset,
      state: widget.state,
    );
    setState(() {
      _seriesData = result.seriesData;
      _isSampled = result.isSampled;
      _totalCount = result.totalCount;
    });
  }

  /// Очищает данные при отсутствии выбранной колонки.
  void _clearData() {
    setState(() {
      _seriesData = [];
      _isSampled = false;
      _totalCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Проверка выбора колонки
    if (widget.state.columnName == null) {
      return const Center(child: Text("Выберите колонку"));
    }
    if (_seriesData.isEmpty || _seriesData.every((s) => s.values.isEmpty)) {
      return const Center(child: Text("Нет данных"));
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final valuesList = _seriesData.map((s) => s.values).toList();
    final labels = _seriesData.map((s) => s.groupName).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Информация о сэмплировании
        if (_isSampled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Показано ${_seriesData.fold(0, (s, series) => s + series.values.length)} из $_totalCount точек (сэмплирование)',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              title: const AxisTitle(text: 'Группа'),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: widget.state.columnName),
            ),
            legend: Legend(isVisible: _seriesData.length > 1),
            series: <BoxAndWhiskerSeries<List<double>, String>>[
              BoxAndWhiskerSeries<List<double>, String>(
                dataSource: valuesList,
                xValueMapper: (_, index) => labels[index],
                yValueMapper: (values, _) => values,
                boxPlotMode: widget.state.boxPlotMode,
                width: widget.state.boxWidth,
                spacing: widget.state.spacing,
                borderWidth: widget.state.borderWidth,
                borderColor: primaryColor,
                color: primaryColor.withValues(alpha: 0.15),
                showMean: widget.state.showMean,
                markerSettings: MarkerSettings(
                  isVisible: widget.state.showOutliers,
                  width: widget.state.outlierSize,
                  height: widget.state.outlierSize,
                  shape: DataMarkerType.circle,
                  borderColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}