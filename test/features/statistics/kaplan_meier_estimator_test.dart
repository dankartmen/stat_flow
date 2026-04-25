import 'package:flutter_test/flutter_test.dart';
import 'package:stat_flow/features/charts/kaplan_meier/kaplan_meier_estimator.dart';

void main() {
  group('KaplanMeierEstimator', () {
    test('пустые данные вызывают ошибку', () {
      expect(
        () => KaplanMeierEstimator.estimate(times: [], events: []),
        throwsArgumentError,
      );
    });

    test('разная длина times и events вызывает ошибку', () {
      expect(
        () => KaplanMeierEstimator.estimate(times: [1.0], events: []),
        throwsArgumentError,
      );
    });

    test('все пациенты выжили (нет событий)', () {
      final result = KaplanMeierEstimator.estimate(
        times: [10.0, 20.0, 30.0],
        events: [0, 0, 0],
      );

      expect(result.points.length, 3);
      expect(result.points.last.survival, closeTo(1.0, 0.001));
      expect(result.totalEvents, 0);
      expect(result.totalCensored, 3);
      // Медиана не достигнута (выживаемость не опускалась ниже 0.5)
      expect(result.medianSurvivalTime, greaterThan(0));
    });

    test('базовый случай: одно событие', () {
      final result = KaplanMeierEstimator.estimate(
        times: [10.0, 20.0, 30.0],
        events: [1, 0, 0],
      );

      expect(result.points.length, 3);
      // После первого события atRisk=3, events=1 => survival = 1 - 1/3 = 0.667
      expect(result.points[0].survival, closeTo(1 - 1/3, 0.001));
      // Дальше выживаемость не меняется
      expect(result.points[2].survival, closeTo(1 - 1/3, 0.001));
      expect(result.totalEvents, 1);
    });

    test('несколько событий в один момент времени', () {
      // Два события в момент t=10
      final result = KaplanMeierEstimator.estimate(
        times: [10.0, 10.0, 20.0],
        events: [1, 1, 0],
      );

      expect(result.points.length, 2); // два временных момента
      // t=10: atRisk=3, events=2 => survival = 1 - 2/3 = 0.333
      expect(result.points.first.survival, closeTo(1 - 2/3, 0.001));
      expect(result.points.first.events, 2);
    });

    test('медиана выживаемости определяется правильно', () {
      final result = KaplanMeierEstimator.estimate(
        times: [1.0, 2.0, 3.0, 4.0],
        events: [1, 1, 0, 1],
      );

      // t=1: surv = 3/4 = 0.75
      // t=2: surv = 0.75 * (1 - 1/3) = 0.5
      // медиана должна быть ≈2
      expect(result.medianSurvivalTime, closeTo(2.0, 0.01));
    });

    test('группировка с помощью log-rank возвращает число', () {
      final g1 = KaplanMeierEstimator.estimate(
        times: [1.0, 2.0, 3.0, 4.0, 5.0],
        events: [1, 0, 1, 1, 0],
        groupName: 'A',
      );
      final g2 = KaplanMeierEstimator.estimate(
        times: [1.5, 2.5, 3.5, 4.5, 5.5],
        events: [0, 1, 0, 1, 1],
        groupName: 'B',
      );
      final chi2 = KaplanMeierEstimator.logRankTest(g1, g2);
      // Просто проверяем, что результат не NaN и не null
      expect(chi2, isA<double>());
      expect(chi2, isNotNaN);
    });
  });
}