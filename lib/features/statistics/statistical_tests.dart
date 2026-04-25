import 'dart:math';

/// {@template statistical_tests}
/// Утилитарный класс для выполнения статистических тестов.
/// Содержит методы для t-теста, хи-квадрат теста, корреляции Пирсона.
/// {@endtemplate}
class StatisticalTests {
  /// Вычисляет t-критерий Стьюдента для независимых выборок (сравнение средних двух групп).
  ///
  /// Принимает:
  /// - [group1] - список значений первой группы.
  /// - [group2] - список значений второй группы.
  ///
  /// Возвращает [TTestResult] с t-статистикой, p-значением и разницей средних.
  /// Если в какой-либо группе меньше 2 элементов, возвращается результат с NaN.
  static TTestResult independentTTest({
    required List<double> group1,
    required List<double> group2,
  }) {
    final n1 = group1.length;
    final n2 = group2.length;

    if (n1 < 2 || n2 < 2) {
      return TTestResult.nan();
    }

    final mean1 = group1.reduce((a, b) => a + b) / n1;
    final mean2 = group2.reduce((a, b) => a + b) / n2;

    // Несмещённые оценки дисперсий (деление на n-1)
    final var1 = group1.map((v) => pow(v - mean1, 2)).reduce((a, b) => a + b) / (n1 - 1);
    final var2 = group2.map((v) => pow(v - mean2, 2)).reduce((a, b) => a + b) / (n2 - 1);

    // Стандартная ошибка разницы средних
    final se = sqrt(var1 / n1 + var2 / n2);

    if (se == 0) {
      return TTestResult(t: 0, pValue: 1.0, meanDiff: mean1 - mean2);
    }

    final t = (mean1 - mean2) / se;

    // Приближённое p-value через нормальное распределение (для больших выборок)
    final pValue = 2 * (1 - _normalCdf(t.abs()));

    return TTestResult(t: t, pValue: pValue, meanDiff: mean1 - mean2);
  }

  /// Вычисляет статистику хи-квадрат для таблицы сопряжённости.
  ///
  /// Принимает:
  /// - [contingencyTable] - двумерный список целых чисел (наблюдаемые частоты).
  ///
  /// Возвращает значение хи-квадрат (без p-value).
  static double chiSquaredTest(List<List<int>> contingencyTable) {
    final rows = contingencyTable.length;
    final cols = contingencyTable[0].length;

    // Суммы по строкам и столбцам
    final rowSums = List.generate(rows, (i) => contingencyTable[i].reduce((a, b) => a + b));
    final colSums = List.generate(cols, (j) {
      int sum = 0;
      for (int i = 0; i < rows; i++) {
        sum += contingencyTable[i][j];
      }
      return sum;
    });
    final total = rowSums.reduce((a, b) => a + b);

    double chi2 = 0;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final expected = rowSums[i] * colSums[j] / total;
        if (expected > 0) {
          final observed = contingencyTable[i][j].toDouble();
          chi2 += (observed - expected) * (observed - expected) / expected;
        }
      }
    }
    return chi2;
  }

  /// Коэффициент корреляции Пирсона между двумя списками чисел.
  ///
  /// Принимает:
  /// - [x] - первый список.
  /// - [y] - второй список (должен быть той же длины).
  ///
  /// Возвращает значение от -1 до 1. Если дисперсия одного из списков равна 0, возвращает 0.
  static double pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0;
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double cov = 0, varX = 0, varY = 0;
    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      cov += dx * dy;
      varX += dx * dx;
      varY += dy * dy;
    }

    if (varX == 0 || varY == 0) return 0;
    return cov / sqrt(varX * varY);
  }

  /// Аппроксимация функции распределения стандартного нормального закона (CDF).
  /// Используется алгоритм Абрамовица и Стегуна, точность ~10^-7.
  static double _normalCdf(double x) {
    // Коэффициенты полинома
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1.0 : 1.0;
    // Приводим аргумент к |x|/sqrt(2)
    double absX = x.abs() / sqrt(2.0);

    final t = 1.0 / (1.0 + p * absX);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX);
    return 0.5 * (1.0 + sign * y);
  }
}

/// {@template t_test_result}
/// Результат t-теста: t-статистика, p-значение и разница средних.
/// {@endtemplate}
class TTestResult {
  /// Значение t-статистики.
  final double t;

  /// P-значение (вероятность ошибки первого рода).
  final double pValue;

  /// Разница средних (mean1 - mean2).
  final double meanDiff;

  /// {@macro t_test_result}
  TTestResult({required this.t, required this.pValue, required this.meanDiff});

  /// Возвращает результат с NaN-полями (используется при невозможности вычисления).
  factory TTestResult.nan() => TTestResult(t: double.nan, pValue: double.nan, meanDiff: double.nan);

  /// Является ли результат статистически значимым (p < 0.05).
  bool get isSignificant => pValue < 0.05;
}