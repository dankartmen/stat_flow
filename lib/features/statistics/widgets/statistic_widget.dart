import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart' hide DataColumn;

import '../column_statistics.dart';
import '../statistic_calculator.dart';
import '../statistic_metrics.dart';

/// {@template statistics_table}
/// Виджет отображения описательной статистики для всех колонок датасета.
///
/// Позволяет выбрать набор статистических метрик (среднее, медиана, количество пропусков и т.д.),
/// которые будут показаны в таблице. Метрики фильтруются по типу колонки (числовая, категориальная и т.п.).
/// {@endtemplate}
class StatisticsTable extends StatefulWidget {
  /// Датасет, для которого строится таблица статистик.
  final Dataset dataset;

  /// {@macro statistics_table}
  const StatisticsTable({super.key, required this.dataset});

  @override
  State<StatisticsTable> createState() => _StatisticsTableState();
}

class _StatisticsTableState extends State<StatisticsTable> {
  /// Набор выбранных пользователем статистических метрик.
  /// Изначально выбраны все возможные метрики.
  Set<StatisticMetric> _selectedMetrics = StatisticMetric.values.toSet();

  @override
  Widget build(BuildContext context) {
    final calculator = StatisticsCalculator();
    // Рассчитываем статистику для каждой колонки
    final allStats = widget.dataset.columns.map((col) => calculator.calculate(col)).toList();

    // Определяем, какие метрики доступны для текущего датасета (хотя бы одна колонка подходит под тип метрики)
    final availableMetrics = StatisticMetric.values.where((metric) {
      return allStats.any((stat) => metric.allowedTypes & _typeToFlag(stat.columnType) != 0);
    }).toList();

    // Формируем заголовки таблицы
    final dataColumns = <DataColumn>[
      const DataColumn(label: Text('Колонка', style: TextStyle(fontWeight: FontWeight.bold))),
      for (final metric in _selectedMetrics.where(availableMetrics.contains))
        DataColumn(label: Text(metric.label, style: const TextStyle(fontWeight: FontWeight.bold))),
    ];

    // Формируем строки таблицы: для каждой колонки — значения выбранных метрик
    final rows = allStats.map((stat) {
      final cells = <DataCell>[
        DataCell(Text(stat.columnName)),
      ];
      for (final metric in _selectedMetrics.where(availableMetrics.contains)) {
        cells.add(DataCell(Text(_formatValue(stat, metric))));
      }
      return DataRow(cells: cells);
    }).toList();

    return Column(
      children: [
        // Панель выбора метрик временно отключена (закомментирована).
        // TODO: Реализовать интерактивный выбор метрик, возможно, через PopupMenuButton или отдельный виджет.
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Wrap(
        //     spacing: 8.0,
        //     children: availableMetrics.map((metric) {
        //       final selected = _selectedMetrics.contains(metric);
        //       return FilterChip(
        //         label: Text(metric.label),
        //         selected: selected,
        //         onSelected: (value) {
        //           setState(() {
        //             if (value) {
        //               _selectedMetrics.add(metric);
        //             } else {
        //               _selectedMetrics.remove(metric);
        //             }
        //           });
        //         },
        //       );
        //     }).toList(),
        //   ),
        // ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: dataColumns,
                rows: rows,
                columnSpacing: 20,
                horizontalMargin: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Преобразует [ColumnType] в битовый флаг, определённый в [ColumnTypeFlags].
  /// Это необходимо для проверки совместимости метрики с типом колонки.
  int _typeToFlag(ColumnType type) {
    switch (type) {
      case ColumnType.numeric:
        return ColumnTypeFlags.numeric;
      case ColumnType.categorical:
        return ColumnTypeFlags.categorical;
      case ColumnType.text:
        return ColumnTypeFlags.text;
      case ColumnType.datetime:
        return ColumnTypeFlags.datetime;
    }
  }

  /// Возвращает строковое представление значения статистики [metric] для колонки [stat].
  /// Для разных типов метрик используются разные поля [ColumnStatistics].
  /// Если значение отсутствует, возвращается '—'.
  String _formatValue(ColumnStatistics stat, StatisticMetric metric) {
    switch (metric) {
      case StatisticMetric.count:
        return stat.validCount.toString();
      case StatisticMetric.missing:
        return '${stat.emptyPercentage.toStringAsFixed(1)}%';
      case StatisticMetric.mean:
        return stat.mean?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.std:
        return stat.std?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.min:
        if (stat.columnType == ColumnType.datetime)
          return stat.minDate != null ? '${stat.minDate!.toLocal().toString().substring(0, 10)}' : '—';
        return stat.min?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.max:
        if (stat.columnType == ColumnType.datetime)
          return stat.maxDate != null ? '${stat.maxDate!.toLocal().toString().substring(0, 10)}' : '—';
        return stat.max?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.q1:
        return stat.q1?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.median:
        return stat.median?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.q3:
        return stat.q3?.toStringAsFixed(2) ?? '—';
      case StatisticMetric.unique:
        return stat.uniqueValues?.toString() ?? '—';
      case StatisticMetric.top:
        return stat.mostFrequent ?? '—';
      case StatisticMetric.topFreq:
        return stat.mostFrequentCount?.toString() ?? '—';
      case StatisticMetric.minLength:
        return stat.minLength?.toString() ?? '—';
      case StatisticMetric.maxLength:
        return stat.maxLength?.toString() ?? '—';
      case StatisticMetric.minDate:
        return stat.minDate != null ? '${stat.minDate!.toLocal().toString().substring(0, 10)}' : '—';
      case StatisticMetric.maxDate:
        return stat.maxDate != null ? '${stat.maxDate!.toLocal().toString().substring(0, 10)}' : '—';
      case StatisticMetric.daysRange:
        return stat.daysRange?.toString() ?? '—';
    }
  }
}