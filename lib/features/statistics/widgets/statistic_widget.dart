import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart' hide DataColumn;
import 'package:stat_flow/features/statistics/statistic_calculator.dart';
import 'package:stat_flow/features/statistics/statistic_result.dart';

/// {@template statistics_table}
/// Виджет для отображения сводной таблицы описательных статистик для всех числовых колонок датасета.
/// 
/// Для каждой числовой колонки рассчитываются:
/// - Количество валидных значений
/// - Среднее, стандартное отклонение
/// - Минимум, максимум
/// - Квартили (25%, 50% (медиана), 75%)
/// - Процент пропусков
/// 
/// Таблица поддерживает горизонтальную и вертикальную прокрутку при большом количестве колонок.
/// Использует [StatisticCalculator] для расчёта метрик.
/// 
/// TODO: Добавить возможность выбора только определённых метрик
/// {@endtemplate}
class StatisticsTable extends StatelessWidget {
  /// Датасет, для которого строится таблица статистик.
  final Dataset dataset;

  /// {@macro statistics_table}
  const StatisticsTable({super.key, required this.dataset});

  @override
  Widget build(BuildContext context) {
    final numericColumns = dataset.numericColumns;
    if (numericColumns.isEmpty) {
      return const Center(child: Text('Нет числовых колонок'));
    }

    final calculator = StatisticCalculator();
    final stats = <String, StatisticResult>{};
    for (final col in numericColumns) {
      stats[col.name] = calculator.calculate(col);
    }

    // Двойной SingleChildScrollView обеспечивает прокрутку в обе стороны:
    // внешний — горизонтальный (если много колонок статистик),
    // внутренний — вертикальный (если много строк-колонок датасета).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Колонка')),
            DataColumn(label: Text('Кол-во')),
            DataColumn(label: Text('Среднее')),
            DataColumn(label: Text('Стд.откл.')),
            DataColumn(label: Text('Мин')),
            DataColumn(label: Text('25%')),
            DataColumn(label: Text('50%')),
            DataColumn(label: Text('75%')),
            DataColumn(label: Text('Макс')),
            DataColumn(label: Text('Пропуски%')),
          ],
          rows: stats.entries.map((entry) {
            final name = entry.key;
            final s = entry.value;
            return DataRow(cells: [
              DataCell(Text(name)),
              DataCell(Text(s.validCount.toString())),
              DataCell(Text(s.mean?.toStringAsFixed(2) ?? '—')),
              DataCell(Text(s.std?.toStringAsFixed(2) ?? '—')),
              DataCell(Text(s.min?.toStringAsFixed(2) ?? '—')),
              DataCell(Text(s.q1?.toStringAsFixed(2) ?? '—')),
              DataCell(Text(s.median?.toStringAsFixed(2) ?? '—')),
              DataCell(Text(s.q3?.toStringAsFixed(2) ?? '—')),
              DataCell(Text(s.max?.toStringAsFixed(2) ?? '—')),
              DataCell(Text('${s.emptyPercentage.toStringAsFixed(1)}%')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}