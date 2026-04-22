/// {@template statistic_result}
/// Результат расчета описательной статистики для ряда данных.
/// 
/// Содержит основные метрики: количество наблюдений, среднее, медиану,
/// стандартное отклонение, квартили, минимум и максимум.
/// Автоматически учитывает пропущенные (null) значения.
/// {@endtemplate}
class StatisticResult {
  /// Общее количество значений в выборке (включая пустые/пропущенные).
  final int totalCount;

  /// Количество непустых (валидных) значений.
  final int validCount;

  /// Количество пустых (null) значений.
  final int emptyCount;
  
  /// Наименьшее значение в выборке (среди валидных).
  final double? min;

  /// Наибольшее значение в выборке.
  final double? max;
  
  /// Среднее арифметическое значение (сумма / количество).
  final double? mean;

  /// Медиана — значение, делящее упорядоченную выборку на две равные части.
  final double? median;

  /// Стандартное отклонение — мера разброса значений относительно среднего.
  /// 
  /// Вычисляется как корень из дисперсии (среднего квадрата отклонений).
  /// Используется формула для генеральной совокупности (деление на n).
  final double? std;
  
  /// 25-й перцентиль (первый квартиль) — значение, ниже которого находятся 25% данных.
  final double? q1;

  /// 75-й перцентиль (третий квартиль).
  final double? q3;

  /// {@macro statistic_result}
  StatisticResult({
    required this.totalCount,
    this.emptyCount = 0,
    this.validCount = 0,
    this.min,
    this.max,
    this.mean,
    this.median,
    this.std,
    this.q1,
    this.q3,
  });

  /// Процент пустых (пропущенных) значений от общего количества.
  /// 
  /// Возвращает:
  /// - процент от 0 до 100, округлённый до одного знака при выводе.
  double get emptyPercentage {
    if (totalCount == 0) return 0;
    return (emptyCount / totalCount) * 100;
  }

  /// Процент валидных (непустых) значений.
  double get validPercentage {
    if (totalCount == 0) return 0;
    return (validCount / totalCount) * 100;
  }

  @override
  String toString() {
    return "StatisticResult: $totalCount, $validCount, $emptyCount, $min, $max, $mean, $median, $std";
  }
}