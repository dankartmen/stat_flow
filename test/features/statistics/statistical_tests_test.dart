import 'package:flutter_test/flutter_test.dart';
import 'package:stat_flow/features/statistics/statistical_tests.dart';

void main() {
  group('StatisticalTests', () {
    group('independentTTest', () {
      test('одинаковые группы', () {
        final result = StatisticalTests.independentTTest(
          group1: [1.0, 2.0, 3.0],
          group2: [1.0, 2.0, 3.0],
        );
        expect(result.t, closeTo(0.0, 0.001));
        expect(result.pValue, closeTo(1.0, 0.01));
      });

      test('заметная разница', () {
        final result = StatisticalTests.independentTTest(
          group1: [10.0, 12.0, 14.0, 16.0],
          group2: [20.0, 22.0, 24.0, 26.0],
        );
        // Разница средних = -10, t должно быть большим по модулю, p-value маленьким
        expect(result.t.abs(), greaterThan(3.0));
        expect(result.pValue, lessThan(0.01));
      });

      test('недостаточно данных', () {
        final result = StatisticalTests.independentTTest(
          group1: [1.0],
          group2: [2.0],
        );
        expect(result.t, isNaN);
        expect(result.pValue, isNaN);
      });
    });

    group('chiSquaredTest', () {
      test('таблица 2x2 без связи', () {
        // Ожидаемые частоты близки к наблюдаемым
        final chi2 = StatisticalTests.chiSquaredTest([
          [10, 10],
          [10, 10],
        ]);
        expect(chi2, closeTo(0.0, 0.001));
      });

      test('явная связь', () {
        final chi2 = StatisticalTests.chiSquaredTest([
          [20, 0],
          [0, 20],
        ]);
        // При сильной связи хи-квадрат большой
        expect(chi2, greaterThan(20.0));
      });
    });

    group('pearsonCorrelation', () {
      test('положительная линейная зависимость', () {
        final r = StatisticalTests.pearsonCorrelation(
          [1.0, 2.0, 3.0],
          [2.0, 4.0, 6.0],
        );
        expect(r, closeTo(1.0, 0.001));
      });

      test('отрицательная зависимость', () {
        final r = StatisticalTests.pearsonCorrelation(
          [1.0, 2.0, 3.0],
          [6.0, 4.0, 2.0],
        );
        expect(r, closeTo(-1.0, 0.001));
      });

      test('нет зависимости', () {
        final r = StatisticalTests.pearsonCorrelation(
          [1.0, 2.0, 3.0, 4.0],
          [5.0, 5.0, 5.0, 5.0], // дисперсия y = 0
        );
        expect(r, equals(0.0)); // из-за нулевой дисперсии возвращает 0
      });
    });
  });
}