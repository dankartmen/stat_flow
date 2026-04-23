import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart' hide DataColumn;
import 'package:stat_flow/features/statistics/statistic_calculator.dart';
import 'package:stat_flow/features/statistics/statistic_result.dart';

/// {@template statistic_metric}
/// Перечисление доступных статистических метрик для отображения в таблице.
/// 
/// Каждая метрика имеет человеко-читаемую подпись ([label]),
/// используемую в заголовках колонок и фильтрах-чипсах.
/// 
/// Значения:
/// - [count] — количество валидных значений
/// - [mean] — среднее арифметическое
/// - [std] — стандартное отклонение
/// - [min] — минимум
/// - [q1] — первый квартиль (25%)
/// - [median] — медиана (50%)
/// - [q3] — третий квартиль (75%)
/// - [max] — максимум
/// - [missing] — процент пропущенных (null) значений
/// {@endtemplate}
enum StatisticMetric {
  count('Кол-во'),
  mean('Среднее'),
  std('Стд.откл.'),
  min('Мин'),
  q1('25%'),
  median('50%'),
  q3('75%'),
  max('Макс'),
  missing('Пропуски%');

  /// Отображаемое название метрики.
  final String label;
  const StatisticMetric(this.label);
}

/// {@template statistics_table}
/// Виджет для отображения сводной таблицы описательных статистик с возможностью выбора метрик.
/// 
/// Особенности:
/// - Пользователь может выбирать, какие статистические метрики показывать, с помощью чипсов.
/// - Таблица автоматически обновляется при изменении набора выбранных метрик.
/// - Поддерживает горизонтальную и вертикальную прокрутку при большом количестве колонок или строк.
/// - Для каждой числовой колонки датасета рассчитываются все метрики,
///   но отображаются только выбранные.
/// 
/// Использует [StatisticCalculator] для расчёта статистик и [StatisticResult] для хранения.
/// {@endtemplate}
class StatisticsTable extends StatefulWidget {
  /// Датасет, для которого строится таблица статистик.
  final Dataset dataset;

  /// {@macro statistics_table}
  const StatisticsTable({super.key, required this.dataset});

  @override
  State<StatisticsTable> createState() => _StatisticsTableState();
}

/// Состояние виджета [StatisticsTable].
/// Отвечает за хранение выбранных метрик и перестроение таблицы при их изменении.
class _StatisticsTableState extends State<StatisticsTable> {
  /// Множество выбранных статистических метрик.
  /// Изначально выбраны все доступные метрики.
  final Set<StatisticMetric> _selectedMetrics = StatisticMetric.values.toSet();

  @override
  Widget build(BuildContext context) {
    final numericColumns = widget.dataset.numericColumns;
    if (numericColumns.isEmpty) {
      return const Center(child: Text('Нет числовых колонок'));
    }

    final calculator = StatisticCalculator();
    final stats = <String, StatisticResult>{};
    for (final col in numericColumns) {
      stats[col.name] = calculator.calculate(col);
    }

    // Динамическое формирование списка колонок DataTable на основе _selectedMetrics
    final dataColumns = <DataColumn>[
      const DataColumn(label: Text('Колонка')),
      if (_selectedMetrics.contains(StatisticMetric.count))
        const DataColumn(label: Text('Кол-во')),
      if (_selectedMetrics.contains(StatisticMetric.mean))
        const DataColumn(label: Text('Среднее')),
      if (_selectedMetrics.contains(StatisticMetric.std))
        const DataColumn(label: Text('Стд.откл.')),
      if (_selectedMetrics.contains(StatisticMetric.min))
        const DataColumn(label: Text('Мин')),
      if (_selectedMetrics.contains(StatisticMetric.q1))
        const DataColumn(label: Text('25%')),
      if (_selectedMetrics.contains(StatisticMetric.median))
        const DataColumn(label: Text('50%')),
      if (_selectedMetrics.contains(StatisticMetric.q3))
        const DataColumn(label: Text('75%')),
      if (_selectedMetrics.contains(StatisticMetric.max))
        const DataColumn(label: Text('Макс')),
      if (_selectedMetrics.contains(StatisticMetric.missing))
        const DataColumn(label: Text('Пропуски%')),
    ];

    return Column(
      children: [
        // Панель фильтров (выбор метрик)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            children: StatisticMetric.values.map((metric) {
              final selected = _selectedMetrics.contains(metric);
              return FilterChip(
                label: Text(metric.label),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedMetrics.add(metric);
                    } else {
                      _selectedMetrics.remove(metric);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: dataColumns,
                rows: stats.entries.map((entry) {
                  final name = entry.key;
                  final s = entry.value;
                  // Формируем список ячеек строки в соответствии с выбранными метриками
                  final cells = <DataCell>[
                    DataCell(Text(name)),
                    if (_selectedMetrics.contains(StatisticMetric.count))
                      DataCell(Text(s.validCount.toString())),
                    if (_selectedMetrics.contains(StatisticMetric.mean))
                      DataCell(Text(s.mean?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.std))
                      DataCell(Text(s.std?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.min))
                      DataCell(Text(s.min?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.q1))
                      DataCell(Text(s.q1?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.median))
                      DataCell(Text(s.median?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.q3))
                      DataCell(Text(s.q3?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.max))
                      DataCell(Text(s.max?.toStringAsFixed(2) ?? '—')),
                    if (_selectedMetrics.contains(StatisticMetric.missing))
                      DataCell(Text('${s.emptyPercentage.toStringAsFixed(1)}%')),
                  ];
                  return DataRow(cells: cells);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}