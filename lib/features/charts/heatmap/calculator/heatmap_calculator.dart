import 'dart:math';

/// {@template heatmap_calculator}
/// Калькулятор для вычисления статистических показателей, используемых в тепловых картах
/// 
/// Предоставляет методы для расчета корреляции между числовыми рядами данных.
/// В текущей реализации поддерживается расчет коэффициента корреляции Пирсона.
/// {@endtemplate}
class HeatmapCalculator {
  /// Расчет коэффициента корреляции Пирсона между двумя рядами данных
  /// 
  /// Принимает:
  /// - [x] — первый список числовых значений (может содержать null)
  /// - [y] — второй список числовых значений (может содержать null)
  /// 
  /// Возвращает:
  /// - [double] — коэффициент корреляции Пирсона в диапазоне от -1 до 1
  /// 
  /// Особенности:
  /// - Пары с null-значениями исключаются из расчета
  /// - Если после исключения null остается меньше 2 пар, возвращает 0
  /// - При нулевом знаменателе (одно из значений постоянно) возвращает 0
  /// 
  /// Выбрасывает:
  /// - [ArgumentError] — если длины списков не совпадают
  static double calculatePearsonCorrelation(List<double?> x, List<double?> y) {
    if (x.length != y.length) {
      throw ArgumentError('Списки должны иметь одинаковую длину');
    }
  
    double sumX = 0.0, sumY = 0.0, sumXY = 0.0;
    double sumX2 = 0.0, sumY2 = 0.0;
    
    int n = 0;

    for (int i = 0; i < x.length; i++) {
      final xi = x[i];
      final yi = y[i];

      if (xi == null || yi == null) continue;

      sumX += xi;
      sumY += yi;
      sumXY += xi * yi;
      sumX2 += xi * xi;
      sumY2 += yi * yi;

      n++;
    }

    if (n < 2) return 0;
    
    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }
}