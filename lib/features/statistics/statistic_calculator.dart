import 'dart:math';

import '../../core/dataset/dataset.dart';
import 'statistic_result.dart';

/// {@template statistic_calculator}
/// Калькулятор для расчета описательной статистики
/// 
/// Автоматически отфильтровывает null-значения при расчете метрик,
/// но учитывает их в подсчете общего количества наблюдений.
/// {@endtemplate}
class StatisticCalculator {

  /// Рассчитывает полную статистику для списка чисел
  /// 
  /// [values] - список значений, может содержать null
  /// 
  /// Возвращает [StatisticResult] со всеми рассчитанными метриками.
  /// Если передан пустой список, возвращается результат только с общим количеством.
  StatisticResult calculate(NumericColumn column) {
    final values = column.data;

    if (values.isEmpty) {
      return StatisticResult(totalCount: 0);
    }

    // Подсчет количества значений
    final totalCount = values.length;
    
    // Фильтрация и преобразование валидных значений
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

    final sorted = List<double>.from(validValues)..sort();

    final min = sorted.first;
    final max = sorted.last;

    final mean = _mean(validValues);
    final median = _median(sorted);
    final std = _std(validValues, mean);

    // Возврат результата со всеми метриками
    return StatisticResult(
      totalCount: totalCount,
      emptyCount: emptyCount,
      validCount: validCount,
      min: min,
      max: max,
      mean: mean,
      median: median,
      std: std,
    );
  }


  /// Вычисляет среднее арифметическое
  double _mean(List<double> values) {
    final sum = values.fold(0.0, (a, b) => a + b);
    return sum / values.length;
  }

  /// Вычисляет медиану (значение, делящее выборку на две равные части)
  double _median(List<double> sortedValues) {
    
    final n = sortedValues.length;
    final mid = n ~/ 2;

    if (n.isOdd) {
      return sortedValues[mid];
    }

    return (sortedValues[mid - 1] + sortedValues[mid]) / 2;
  }

  /// Вычисляет стандартное отклонение (меру разброса значений)
  /// 
  /// Используется формула для генеральной совокупности (деление на n)
  double? _std(List<double> values, double mean) {
    final sumSquaredDiff = values.fold(
      0.0,
      (sum, v) {
        final diff = v - mean;
        return sum + diff * diff;
      },
    );

    return sqrt(sumSquaredDiff / values.length);
  }
}