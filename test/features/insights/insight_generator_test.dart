import 'package:flutter_test/flutter_test.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/insights/insight_generator.dart';

void main() {
  group('InsightGenerator', () {
    test('датасет без целевой переменной', () {
      final dataset = Dataset(name: 'test', columns: [
        NumericColumn('x', [1.0, 2.0]),
      ]);
      final insights = InsightGenerator.generate(dataset);
      expect(insights, isNotEmpty);
      expect(insights.first.type, InsightType.info);
      expect(insights.first.text, contains('не найдена'));
    });

    test('распознаёт значимые различия в числовых колонках', () {
      // DEATH_EVENT: первые 5 живы (0), вторые 5 умерли (1)
      final deathEvent = NumericColumn('DEATH_EVENT', [
        0.0, 0.0, 0.0, 0.0, 0.0,
        1.0, 1.0, 1.0, 1.0, 1.0,
      ]);
      // Значения: у выживших маленькие, у умерших большие
      final serum = NumericColumn('serum_creatinine', [
        1.0, 1.2, 0.9, 1.1, 1.0,
        3.0, 3.5, 2.8, 3.2, 3.1,
      ]);

      final dataset = Dataset(name: 'heart', columns: [deathEvent, serum]);
      final insights = InsightGenerator.generate(dataset);

      // Должен быть вывод о значимом различии serum_creatinine
      final serumInsights = insights.where((i) => i.text.contains('serum_creatinine'));
      expect(serumInsights, isNotEmpty);
      final main = serumInsights.first;
      expect(main.text, contains('значимое различие'));
      expect(main.type, InsightType.strong); // p-value очень маленький
    });

    test('категориальная связь с исходом', () {
      final death = NumericColumn('DEATH_EVENT', [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        1.0, 1.0, 1.0, 1.0,
      ]);
      // Признак: все выжившие имеют 'A', умершие — 'B'
      final sex = CategoricalColumn('sex', [
        'A', 'A', 'A', 'A', 'A', 'A',
        'B', 'B', 'B', 'B',
      ]);
      final dataset = Dataset(name: 'test', columns: [death, sex]);
      final insights = InsightGenerator.generate(dataset);

      final sexInsights = insights.where((i) => i.text.contains('sex'));
      expect(sexInsights, isNotEmpty);
      expect(sexInsights.first.text, contains('χ²='));
    });

    test('корреляция с исходом отображается', () {
      final death = NumericColumn('DEATH_EVENT', [0.0,0.0,0.0,1.0,1.0,1.0]);
      final age = NumericColumn('age', [40.0,45.0,50.0,70.0,75.0,80.0]);
      final dataset = Dataset(name:'test', columns:[death, age]);
      final insights = InsightGenerator.generate(dataset);

      // Сводим весь текст в одну строку и проверяем наличие ожидаемых терминов
      final allText = insights.map((i) => i.text).join('\n');
      expect(allText, contains('корреляция'));
      expect(allText, contains('age'));
    });
  });
}