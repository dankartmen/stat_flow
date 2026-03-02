import 'dart:math';

import 'statistic_result.dart';

/// {@template statistic_calculator}
/// Калькулятор для расчета описательной статистики
/// 
/// Работает только с числовыми данными ([ColumnType.numeric]).
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
  StatisticResult calculate(List<num?> values) {
    if (values.isEmpty) {
      return StatisticResult(totalCount: 0);
    }

    // Подсчет количества значений
    final totalCount = values.length;
    
    // Фильтрация и преобразование валидных значений
    final validValues = values
        .where((v) => v != null)
        .map((v) => v!.toDouble())
        .toList();
    
    final validCount = validValues.length;
    final emptyCount = totalCount - validCount;

    // Возврат результата со всеми метриками
    return StatisticResult(
      totalCount: totalCount,
      emptyCount: emptyCount,
      validCount: validCount,
      min: _calculateMin(validValues),
      max: _calculateMax(validValues),
      mean: _calculateMean(validValues),
      median: _calculateMedian(validValues),
      std: _calculateStd(validValues),
    );
  }

  /// Вычисляет минимальное значение в списке
  /// 
  /// Возвращает null, если список пуст.
  double? _calculateMin(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Вычисляет максимальное значение в списке
  /// 
  /// Возвращает null, если список пуст.
  double? _calculateMax(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Вычисляет среднее арифметическое
  /// 
  /// Возвращает null, если список пуст.
  double? _calculateMean(List<double> values) {
    if (values.isEmpty) return null;
    
    final sum = values.fold(0.0, (a, b) => a + b);
    return sum / values.length;
  }

  /// Вычисляет медиану (значение, делящее выборку на две равные части)
  /// 
  /// Возвращает null, если список пуст.
  double? _calculateMedian(List<double> values) {
    if (values.isEmpty) return null;
    
    // Сортируем копию списка, чтобы не изменять исходный
    final sortedValues = List<double>.from(values)..sort();
    final middleIndex = sortedValues.length ~/ 2;

    // Для нечетного количества элементов возвращаем средний
    // Для четного — среднее арифметическое двух центральных
    if (sortedValues.length % 2 == 1) {
      return sortedValues[middleIndex];
    } else {
      return (sortedValues[middleIndex - 1] + sortedValues[middleIndex]) / 2;
    }
  }

  /// Вычисляет стандартное отклонение (меру разброса значений)
  /// 
  /// Возвращает null, если список пуст.
  /// 
  /// Используется формула для генеральной совокупности (деление на n),
  /// а не на n-1 (как для выборки).
  double? _calculateStd(List<double> values) {
    if (values.isEmpty) return null;
    
    final mean = _calculateMean(values)!; // mean точно не null, так как values не пуст
    
    // Сумма квадратов отклонений от среднего
    final sumSquaredDiff = values.fold(0.0, (sum, value) {
      final diff = value - mean;
      return sum + diff * diff;
    });
    
    return sqrt(sumSquaredDiff / values.length);
  }
}