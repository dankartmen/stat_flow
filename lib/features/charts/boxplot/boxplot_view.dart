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
    final columnName = widget.state.columnName;
    if (columnName == null) {
      _clearData();
      return;
    }

    final column = widget.dataset.numeric(columnName);
    final allValues = column.data;

    // Обработка с группировкой
    if (widget.state.groupByColumn != null) {
      final groupColName = widget.state.groupByColumn!;
      final groupCol = widget.dataset.column(groupColName);
      if (groupCol == null) {
        _clearData();
        return;
      }

      // Приводим группирующую колонку к списку строк
      List<String?> groupData;
      if (groupCol is CategoricalColumn) {
        groupData = groupCol.data;
      } else if (groupCol is TextColumn) {
        groupData = groupCol.data;
      } else {
        _clearData();
        return;
      }

      // Группируем числовые значения по категориям
      final Map<String, List<double>> groupsMap = {};
      for (int i = 0; i < allValues.length; i++) {
        final val = allValues[i];
        final group = groupData[i];
        if (val != null && group != null) {
          groupsMap.putIfAbsent(group, () => []).add(val);
        }
      }

      // Сортируем группы для стабильного порядка
      final sortedGroups = groupsMap.keys.toList()..sort();

      final List<BoxPlotSeriesData> newSeriesData = [];
      int totalBefore = 0;

      for (final group in sortedGroups) {
        final values = groupsMap[group]!;
        totalBefore += values.length;

        // Сэмплирование при необходимости
        final sampledValues = values.length > widget.state.maxPoints
            ? values.sample(widget.state.maxPoints)
            : values;

        newSeriesData.add(BoxPlotSeriesData(group, sampledValues));
      }

      final totalAfter = newSeriesData.fold(0, (sum, series) => sum + series.values.length);

      setState(() {
        _seriesData = newSeriesData;
        _isSampled = totalAfter < totalBefore;
        _totalCount = totalBefore;
      });
    } else {
      // Без группировки — одна серия
      final validValues = allValues.whereType<double>().toList();
      final sampled = validValues.length > widget.state.maxPoints
          ? validValues.sample(widget.state.maxPoints)
          : validValues;

      setState(() {
        _seriesData = [BoxPlotSeriesData(columnName, sampled)];
        _isSampled = sampled.length < validValues.length;
        _totalCount = validValues.length;
      });
    }
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

/// Данные для одной серии (группы) ящика с усами.
class BoxPlotSeriesData {
  /// Название группы (категория или имя колонки).
  final String groupName;

  /// Список числовых значений в этой группе.
  final List<double> values;

  /// {@macro boxplot_series_data}
  BoxPlotSeriesData(this.groupName, this.values);
}