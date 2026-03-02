/// {@template statistic_result}
/// Результат расчета описательной статистики для ряда данных
/// {@endtemplate}
class StatisticResult {
  /// Общее количество значений в выборке (включая пустые)
  final int totalCount;

  /// Количество непустых (валидных) значений в выборке
  final int? validCount;

  /// Количество пустых (null) значений в выборке
  final int? emptyCount;
  
  /// Наименьшее значение в выборке
  final double? min;

  /// Наибольшее значение в выборке
  final double? max;
  
  /// Среднее арифмитическое значение
  final double? mean;

  /// Медиана - значение, делящее выборку на 2 равные части
  final double? median;

  /// Стандартное отклонение - мера разброса значений относительно среднего
  final double? std;
 
  /// {macro statictic_result}
  StatisticResult({
    required this.totalCount,
    this.emptyCount,
    this.validCount,
    this.min,
    this.max,
    this.mean,
    this.median,
    this.std,
  });

  /// Процент пустых значений
  double get emptyPercentage{
    if(totalCount == 0 && emptyCount == null) return 0;
    return (emptyCount! / totalCount) * 100;
  }

  /// Процент валидных значений
  double get validPercentage{
    if(totalCount == 0 && validCount == null) return 0;
    return (validCount! / totalCount) * 100;
  }

  @override
  String toString() {
    return "StatisticResult: $totalCount, $validCount, $emptyCount, $min, $max, $mean, $median, $std";
  }
}
