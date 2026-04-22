import 'dart:math';

import '../../core/dataset/dataset.dart';
import 'statistic_result.dart';

/// {@template statistic_calculator}
/// Калькулятор для расчёта описательной статистики числовой колонки.
/// 
/// Автоматически отфильтровывает null-значения при расчёте метрик,
/// но учитывает их в подсчёте общего количества наблюдений.
/// 
/// Поддерживаемые метрики:
/// - Количество (общее, валидных, пустых)
/// - Минимум, максимум
/// - Среднее арифметическое
/// - Медиана
/// - Стандартное отклонение (генеральная совокупность)
/// - Первый и третий квартили (25% и 75% перцентили)
/// {@endtemplate}
class StatisticCalculator {
  /// Рассчитывает полную статистику для числовой колонки.
  /// 
  /// Принимает:
  /// - [column] — колонка с числовыми данными (может содержать null).
  /// 
  /// Возвращает:
  /// - [StatisticResult] со всеми рассчитанными метриками.
  ///   Если передан пустой список, возвращается результат только с общим количеством.
  StatisticResult calculate(NumericColumn column) {
    final values = column.data;

    if (values.isEmpty) {
      return StatisticResult(totalCount: 0);
    }

    final totalCount = values.length;
    
    // Фильтруем только валидные (не-null) значения
    final validValues = values.whereType<double>().toList();
    final validCount = validValues.length;
    final emptyCount = totalCount - validCount;

    if (validValues.isEmpty) {
      return StatisticResult(
        totalCount: totalCount,
        emptyCount: emptyCount,
        validCount: validCount,
      );
    }

    // Сортируем для квартилей и медианы
    final sorted = List<double>.from(validValues)..sort();

    final min = sorted.first;
    final max = sorted.last;

    final mean = _mean(validValues);
    final median = _median(sorted);
    final std = _std(validValues, mean);

    final q1 = _percentile(sorted, 0.25);
    final q3 = _percentile(sorted, 0.75);
    
    return StatisticResult(
      totalCount: totalCount,
      emptyCount: emptyCount,
      validCount: validCount,
      min: min,
      max: max,
      mean: mean,
      median: median,
      std: std,
      q1: q1,
      q3: q3,
    );
  }

  /// Вычисляет среднее арифметическое.
  /// 
  /// Принимает:
  /// - [values] — список валидных чисел (не пустой).
  /// 
  /// Возвращает:
  /// - среднее значение (сумма / количество).
  double _mean(List<double> values) {
    final sum = values.fold(0.0, (a, b) => a + b);
    return sum / values.length;
  }

  /// Вычисляет медиану (значение, делящее выборку на две равные части).
  /// 
  /// Принимает:
  /// - [sortedValues] — отсортированный по возрастанию список валидных чисел.
  /// 
  /// Возвращает:
  /// - медиану: для нечётного количества — центральный элемент,
  ///   для чётного — среднее арифметическое двух центральных.
  double _median(List<double> sortedValues) {
    final n = sortedValues.length;
    final mid = n ~/ 2;

    if (n.isOdd) {
      return sortedValues[mid];
    }

    return (sortedValues[mid - 1] + sortedValues[mid]) / 2;
  }

  /// Вычисляет стандартное отклонение (меру разброса значений относительно среднего).
  /// 
  /// Принимает:
  /// - [values] — список валидных чисел.
  /// - [mean] — среднее арифметическое этих чисел (предвычисленное).
  /// 
  /// Возвращает:
  /// - стандартное отклонение по формуле для генеральной совокупности:
  ///   σ = sqrt( Σ(x - mean)² / n )
  double _std(List<double> values, double mean) {
    final sumSquaredDiff = values.fold(
      0.0,
      (sum, v) {
        final diff = v - mean;
        return sum + diff * diff;
      },
    );
    return sqrt(sumSquaredDiff / values.length);
  }
  
  /// Вычисляет перцентиль по отсортированному списку.
  /// 
  /// Принимает:
  /// - [sorted] — отсортированный по возрастанию список валидных чисел.
  /// - [fraction] — доля от 0.0 до 1.0 (например, 0.25 для 25-го перцентиля).
  /// 
  /// Возвращает:
  /// - значение перцентиля с линейной интерполяцией между ближайшими элементами.
  /// 
  /// Алгоритм:
  /// 1. Вычисляет позицию: index = (n - 1) * fraction
  /// 2. Если index целое — возвращает элемент по этому индексу.
  /// 3. Иначе — линейно интерполирует между элементами floor и ceil.
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