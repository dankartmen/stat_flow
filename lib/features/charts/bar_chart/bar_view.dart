import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'bar_state.dart';

const int _kMaxChartPoints = 5000;

/// {@template bar_view}
/// Виджет для отображения столбчатой диаграммы
/// 
/// Использует SyncFusion Charts для построения интерактивной столбчатой диаграммы
/// с поддержкой:
/// - Отображения распределения категориальных данных (частоты)
/// - Группировки числовых данных в интервалы (гистограмма)
/// - Подписей значений на столбцах
/// - Настраиваемой ширины столбцов
/// - Сэмплирования для больших наборов данных
/// 
/// Автоматически определяет тип данных и строит соответствующее представление.
/// {@endtemplate}
class BarView extends StatefulWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние столбчатой диаграммы с настройками
  final BarState state;

  /// {@macro bar_view}
  const BarView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<BarView> createState() => _BarViewState();
}

class _BarViewState extends State<BarView> {
  /// Данные для отображения в виде пар (категория, значение)
  List<BarData> _barData = [];

  /// Флаг, указывающий, что данные были сэмплированы
  bool _isSampled = false;

  /// Тип колонки (для логирования)
  String? _columnType;

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  @override
  void didUpdateWidget(covariant BarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем данные только если изменились параметры, влияющие на расчёт
    if (oldWidget.dataset != widget.dataset ||
        oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.state.binCount != widget.state.binCount ||
        oldWidget.state.maxCategories != widget.state.maxCategories ||
        oldWidget.state.sortDescending != widget.state.sortDescending) {
      _updateData();
    }
  }

  /// Обновляет данные на основе выбранной колонки
  /// - Определяет тип колонки и обрабатывает данные соответствующим образом
  /// - Для числовых данных выполняет группировку в интервалы (гистограмма
  /// - Для категориальных и текстовых данных считает частоты
  /// - Выполняет сэмплирование, если количество данных превышает порог для производительности
  /// Принимает:
  /// - [widget.state.columnName] — имя выбранной колонки для построения диаг
  /// - [widget.dataset] — датасет с данными для анализа
  /// - [widget.state.binCount] — количество интервалов для числовых данных
  /// - [widget.state.maxCategories] — максимальное количество категорий для отображения
  /// - [widget.state.sortDescending] — флаг сортировки категорий по убыванию
  /// Возвращает:
  /// - Подготовленные данные для отображения на столбчатой диаграмме
  void _updateData() {
    log("Обновление данных в BarView с состоянием: ${widget.state.toString()}", name: 'BarView');
    
    if (widget.state.columnName == null) {
      _clearData();
      return;
    }

    final column = widget.dataset.column(widget.state.columnName!);
    if (column == null) {
      _clearData();
      return;
    }

    if (column is NumericColumn) {
      _columnType = 'numeric';
      _processNumericColumn(column);
    } else if (column is CategoricalColumn) {
      _columnType = 'categorical';
      _processCategoricalColumn(column);
    } else if (column is TextColumn) {
      _columnType = 'text';
      _processTextColumn(column);
    } else {
      _clearData();
    }
  }

  /// Очищает данные при отсутствии выбранной колонки
  void _clearData() {
    setState(() {
      _barData = [];
      _isSampled = false;
    });
  }

  /// Обрабатывает числовую колонку (строит гистограмму)
  void _processNumericColumn(NumericColumn column) {
    final allValues = column.data.whereType<double>().toList();
    if (allValues.isEmpty) {
      _clearData();
      return;
    }

    // Для числовых данных группируем по диапазонам (гистограмма)
    final values = allValues.length > _kMaxChartPoints
        ? allValues.sample(_kMaxChartPoints)
        : allValues;

    // Создаем гистограмму для числовых данных
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final binCount = widget.state.binCount; // исправлено: используется настройка
    final binWidth = (max - min) / binCount;
    
    final bins = List.generate(binCount, (i) {
      final binMin = min + i * binWidth;
      final binMax = binMin + binWidth;
      final count = values.where((v) => v >= binMin && v < binMax).length;
      return BarData('${binMin.toStringAsFixed(2)}-${binMax.toStringAsFixed(2)}', count.toDouble());
    });

    setState(() {
      _isSampled = values.length != allValues.length;
      _barData = bins;
    });
  }

  /// Обрабатывает категориальную колонку (считает частоты)
  void _processCategoricalColumn(CategoricalColumn column) {
    // Группируем по категориям и считаем частоты
    final valueCounts = <String, int>{};
    
    for (final value in column.data) {
      if (value != null) {
        valueCounts[value] = (valueCounts[value] ?? 0) + 1;
      }
    }
    final entries = valueCounts.entries.toList();
    if (widget.state.sortDescending) {
      entries.sort((a, b) => b.value.compareTo(a.value));
    } else {
      entries.sort((a, b) => a.value.compareTo(b.value));
    }
    final maxCat = widget.state.maxCategories;
    final topEntries = entries.take(maxCat).toList();
    setState(() {
      _isSampled = entries.length > maxCat;
      _barData = topEntries.map((e) => BarData(e.key, e.value.toDouble())).toList();
    });
  }

  /// Обрабатывает текстовую колонку (считает частоты, аналогично categorical)
  void _processTextColumn(TextColumn column) {
    final valueCounts = <String, int>{};
    for (final value in column.data) {
      if (value != null && value.isNotEmpty) {
        valueCounts[value] = (valueCounts[value] ?? 0) + 1;
      }
    }
    final entries = valueCounts.entries.toList();
    if (widget.state.sortDescending) {
      entries.sort((a, b) => b.value.compareTo(a.value));
    } else {
      entries.sort((a, b) => a.value.compareTo(b.value));
    }
    final maxCat = widget.state.maxCategories;
    final topEntries = entries.take(maxCat).toList();
    setState(() {
      _isSampled = entries.length > maxCat;
      _barData = topEntries.map((e) => BarData(e.key, e.value.toDouble())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_barData.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        if (_isSampled) _buildSamplingInfo(),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              tooltipSettings: const InteractiveTooltip(format: 'point.x : point.y'),
            ),
            tooltipBehavior: TooltipBehavior(enable: false, duration: 2500),
            primaryXAxis: CategoryAxis(
              labelRotation: 45,
              labelIntersectAction: AxisLabelIntersectAction.multipleRows,
            ),
            primaryYAxis: const NumericAxis(),
            series: [
              BarSeries<BarData, String>(
                dataSource: _barData,
                xValueMapper: (data, _) => data.category,
                yValueMapper: (data, _) => data.value,
                width: widget.state.barWidth,
                spacing: widget.state.spacing,
                borderRadius: BorderRadius.circular(widget.state.borderRadius),
                borderWidth: widget.state.borderWidth,
                borderColor: primaryColor,
                color: primaryColor.withValues(alpha: 0.85),
                isTrackVisible: widget.state.showTrack,
                trackColor: theme.colorScheme.surfaceContainerHighest,
                dataLabelSettings: DataLabelSettings(
                  isVisible: widget.state.showValues,
                  alignment: _getBarAlignment(widget.state.alignment),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSamplingInfo() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "Показано ${_barData.length} из ${widget.dataset.rowCount} строк (выборка)",
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

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

/// {@template bar_data}
/// Вспомогательный класс для хранения данных столбчатой диаграммы
/// {@endtemplate}
class BarData {
  /// Название категории
  final String category;

  /// Значение (частота или другое числовое значение)
  final double value;

  /// {@macro bar_data}
  BarData(this.category, this.value);
}