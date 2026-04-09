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
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние ящика с усами с настройками
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

class _BoxPlotViewState extends State<BoxPlotView> {
  /// Все значения для отображения на ящике с усами
  late List<double> _displayValues;
  /// Флаг, указывающий, были ли данные сэмплированы для производительности
  late bool _isSampled;
  /// Общее количество точек в выбранной колонке (до сэмплирования)
  late int _totalCount;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant BoxPlotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.state.maxPoints != widget.state.maxPoints ||
        oldWidget.dataset != widget.dataset) {
      _prepareData();
    }
  }
  
  /// Подготавливает данные для отображения на ящике с усами
  /// - Извлекает числовые значения из выбранной колонки
  /// - Выполняет сэмплирование, если количество точек превышает порог для производительности
  /// Приоритет: если maxPoints <= 0 – отображаем все данные, иначе сэмплируем до maxPoints
  void _prepareData() {
    final columnName = widget.state.columnName;
    if (columnName == null) {
      _displayValues = [];
      _isSampled = false;
      _totalCount = 0;
      return;
    }

    final column = widget.dataset.numeric(columnName);
    final allValues = column.data.whereType<double>().toList();
    _totalCount = allValues.length;

    final maxPoints = widget.state.maxPoints <= 0 ? allValues.length : widget.state.maxPoints;
    if (allValues.length > maxPoints) {
      _displayValues = allValues.sample(maxPoints);
      _isSampled = true;
    } else {
      _displayValues = allValues;
      _isSampled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Проверка выбора колонки
    if (widget.state.columnName == null) {
      return const Center(child: Text("Выберите колонку"));
    }
    if (_displayValues.isEmpty) {
      return const Center(child: Text("Нет данных"));
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSampled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Показано ${_displayValues.length} из $_totalCount точек (сэмплирование)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            // Настройка оси X как категориальной (для одной колонки)
            primaryXAxis: const CategoryAxis(
              title: AxisTitle(text: 'Поле'),
            ),
            primaryYAxis: const NumericAxis(
              title: AxisTitle(text: 'Значение'),
            ),
            // Серия данных - ящик с усами
            series: <BoxAndWhiskerSeries<List<double>, String>>[
              BoxAndWhiskerSeries<List<double>, String>(
                dataSource: [_displayValues],
                xValueMapper: (_, __) => widget.state.columnName!,
                yValueMapper: (v, _) => v,
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
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}