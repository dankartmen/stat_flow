import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'bar_state.dart';

/// Максимальное количество точек для отображения (для производительности)
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
  _BarViewState createState() => _BarViewState();
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
    _updateData(widget.dataset, widget.state);
  }

  @override
  void didUpdateWidget(covariant BarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataset != widget.dataset ||
        oldWidget.state.columnName != widget.state.columnName) {
      _updateData(widget.dataset, widget.state);
    }
  }

  /// Обновляет данные на основе выбранной колонки
  void _updateData(Dataset dataset, BarState state) {
    log("Обновление данных в BarView с состоянием: ${state.toString()}", name: 'BarView');
    
    if (state.columnName == null) {
      _clearData();
      return;
    }

    final column = dataset.column(state.columnName!);
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
    final binCount = 10; // можно сделать настраиваемым
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

    // Сортируем по убыванию частоты и ограничиваем количество
    final sortedEntries = valueCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topEntries = sortedEntries.take(20).toList(); // показываем топ-20 категорий

    setState(() {
      _isSampled = sortedEntries.length > 20;
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

    final sortedEntries = valueCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topEntries = sortedEntries.take(20).toList();

    setState(() {
      _isSampled = sortedEntries.length > 20;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSampled)
          _buildSamplingInfo(),
        Expanded(
          child: SfCartesianChart(
            tooltipBehavior: _buildTooltipBehavior(),
            primaryXAxis: _buildXAxis(),
            primaryYAxis: _buildYAxis(),
            series: _buildSeries(),
          ),
        ),
      ],
    );
  }

  /// Строит информацию о сэмплировании
  Widget _buildSamplingInfo() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "Показано ${_barData.length} из ${widget.dataset.rowCount} строк (выборка)",
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  /// Строит поведение всплывающих подсказок
  TooltipBehavior _buildTooltipBehavior() {
    return TooltipBehavior(
      enable: true,
      duration: 2000,
      header: widget.state.columnName ?? 'Столбчатая диаграмма',
      activationMode: ActivationMode.singleTap,
      format: 'Категория: point.x\nЗначение: point.y',
    );
  }

  /// Строит ось X (категориальная)
  CategoryAxis _buildXAxis() {
    return CategoryAxis(
      title: const AxisTitle(text: 'Категория'),
      labelRotation: 45,
      labelIntersectAction: AxisLabelIntersectAction.multipleRows,
    );
  }

  /// Строит ось Y (числовая)
  NumericAxis _buildYAxis() {
    return NumericAxis(
      title: AxisTitle(text: widget.state.columnName),
    );
  }

  /// Строит серию данных для столбчатой диаграммы
  List<BarSeries<BarData, String>> _buildSeries() {
    return [
      BarSeries<BarData, String>(
        dataSource: _barData,
        xValueMapper: (data, _) => data.category,
        yValueMapper: (data, _) => data.value,
        width: widget.state.barWidth,
        dataLabelSettings: DataLabelSettings(
          alignment: _getBarAlignment(widget.state.alignment),
          isVisible: widget.state.showValues,
          textStyle: const TextStyle(fontSize: 10),
        ),
      ),
    ];
  }

  /// Преобразование BarAlignment в ChartAlignment
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