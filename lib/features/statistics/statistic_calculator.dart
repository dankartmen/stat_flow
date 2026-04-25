import 'dart:math';
import '../../core/dataset/dataset.dart';
import 'column_statistics.dart';

/// {@template statistics_calculator}
/// Класс для вычисления описательной статистики по колонкам датасета.
/// Поддерживает числовые, категориальные, текстовые колонки и колонки с датами.
/// {@endtemplate}
class StatisticsCalculator {
  /// Вычисляет статистику для одной колонки [column] в зависимости от её реального типа.
  ColumnStatistics calculate(DataColumn column) {
    if (column is NumericColumn) {
      return _calculateNumeric(column);
    } else if (column is CategoricalColumn) {
      return _calculateCategorical(column);
    } else if (column is TextColumn) {
      return _calculateText(column);
    } else if (column is DateTimeColumn) {
      return _calculateDateTime(column);
    }
    throw Exception('Unknown column type');
  }

  /// Вычисляет статистику для числовой колонки.
  ColumnStatistics _calculateNumeric(NumericColumn column) {
    final values = column.data;
    final totalCount = values.length;
    final validValues = values.whereType<double>().toList();
    final validCount = validValues.length;
    final emptyCount = totalCount - validCount;

    if (validValues.isEmpty) {
      return ColumnStatistics(
        columnName: column.name,
        columnType: ColumnType.numeric,
        totalCount: totalCount,
        validCount: validCount,
        emptyCount: emptyCount,
      );
    }

    final sorted = List<double>.from(validValues)..sort();
    final min = sorted.first;
    final max = sorted.last;
    final mean = validValues.reduce((a, b) => a + b) / validCount;
    final median = _median(sorted);
    final std = _std(validValues, mean);
    final q1 = _percentile(sorted, 0.25);
    final q3 = _percentile(sorted, 0.75);

    return ColumnStatistics(
      columnName: column.name,
      columnType: ColumnType.numeric,
      totalCount: totalCount,
      validCount: validCount,
      emptyCount: emptyCount,
      min: min,
      max: max,
      mean: mean,
      median: median,
      std: std,
      q1: q1,
      q3: q3,
    );
  }

  /// Вычисляет статистику для категориальной колонки (строки с ограниченным набором значений).
  ColumnStatistics _calculateCategorical(CategoricalColumn column) {
    final values = column.data;
    final totalCount = values.length;
    final validValues = values.whereType<String>().toList();
    final validCount = validValues.length;
    final emptyCount = totalCount - validCount;

    if (validValues.isEmpty) {
      return ColumnStatistics(
        columnName: column.name,
        columnType: ColumnType.categorical,
        totalCount: totalCount,
        validCount: validCount,
        emptyCount: emptyCount,
      );
    }

    // Подсчёт частоты каждого значения
    final freq = <String, int>{};
    for (final v in validValues) freq[v] = (freq[v] ?? 0) + 1;
    final uniqueValues = freq.length;
    // Находим самое частое значение
    final mostFrequentEntry = freq.entries.reduce((a, b) => a.value > b.value ? a : b);

    return ColumnStatistics(
      columnName: column.name,
      columnType: ColumnType.categorical,
      totalCount: totalCount,
      validCount: validCount,
      emptyCount: emptyCount,
      uniqueValues: uniqueValues,
      mostFrequent: mostFrequentEntry.key,
      mostFrequentCount: mostFrequentEntry.value,
    );
  }

  /// Вычисляет статистику для текстовой колонки (длины строк, частоты и т.д.).
  ColumnStatistics _calculateText(TextColumn column) {
    final values = column.data;
    final totalCount = values.length;
    final validValues = values.whereType<String>().toList();
    final validCount = validValues.length;
    final emptyCount = totalCount - validCount;

    if (validValues.isEmpty) {
      return ColumnStatistics(
        columnName: column.name,
        columnType: ColumnType.text,
        totalCount: totalCount,
        validCount: validCount,
        emptyCount: emptyCount,
      );
    }

    final uniqueValues = validValues.toSet().length;
    final lengths = validValues.map((s) => s.length);
    final minLength = lengths.reduce((a, b) => a < b ? a : b);
    final maxLength = lengths.reduce((a, b) => a > b ? a : b);

    final freq = <String, int>{};
    for (final v in validValues) freq[v] = (freq[v] ?? 0) + 1;
    final mostFrequentEntry = freq.entries.reduce((a, b) => a.value > b.value ? a : b);

    return ColumnStatistics(
      columnName: column.name,
      columnType: ColumnType.text,
      totalCount: totalCount,
      validCount: validCount,
      emptyCount: emptyCount,
      uniqueValues: uniqueValues,
      mostFrequent: mostFrequentEntry.key,
      mostFrequentCount: mostFrequentEntry.value,
      minLength: minLength,
      maxLength: maxLength,
    );
  }

  /// Вычисляет статистику для колонки с датами (мин, макс, диапазон в днях).
  ColumnStatistics _calculateDateTime(DateTimeColumn column) {
    final values = column.data;
    final totalCount = values.length;
    final validValues = values.whereType<DateTime>().toList();
    final validCount = validValues.length;
    final emptyCount = totalCount - validCount;

    if (validValues.isEmpty) {
      return ColumnStatistics(
        columnName: column.name,
        columnType: ColumnType.datetime,
        totalCount: totalCount,
        validCount: validCount,
        emptyCount: emptyCount,
      );
    }

    final minDate = validValues.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = validValues.reduce((a, b) => a.isAfter(b) ? a : b);
    final daysRange = maxDate.difference(minDate).inDays;

    return ColumnStatistics(
      columnName: column.name,
      columnType: ColumnType.datetime,
      totalCount: totalCount,
      validCount: validCount,
      emptyCount: emptyCount,
      minDate: minDate,
      maxDate: maxDate,
      daysRange: daysRange,
    );
  }

  /// Вычисляет медиану для отсортированного списка чисел [sorted].
  double _median(List<double> sorted) {
    final n = sorted.length;
    final mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Вычисляет стандартное отклонение (для генеральной совокупности, деление на n).
  double _std(List<double> values, double mean) {
    final sumSqDiff = values.fold(0.0, (sum, v) {
      final diff = v - mean;
      return sum + diff * diff;
    });
    return sqrt(sumSqDiff / values.length);
  }

  /// Вычисляет заданный перцентиль (квантиль) для отсортированного списка [sorted].
  /// [fraction] — значение от 0 до 1 (например, 0.25 для 25-го перцентиля).
  /// Используется линейная интерполяция между соседними элементами.
  double _percentile(List<double> sorted, double fraction) {
    if (sorted.isEmpty) return 0.0;
    final index = (sorted.length - 1) * fraction;
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return sorted[lower];
    final weight = index - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }
}