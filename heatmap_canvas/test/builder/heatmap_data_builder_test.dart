import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/src/builder/heatmap_data_builder.dart';

void main() {
  group('HeatmapDataBuilder.pearsonCorrelation', () {
    test('должен вычислить корреляцию 1.0 для идеально положительной связи', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [2.0, 4.0, 6.0, 8.0, 10.0];
      final columns = [
        x.map((e) => e as double?).toList(),
        y.map((e) => e as double?).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      final corr = result.values[0][1];

      expect(corr, closeTo(1.0, 1e-6));
      expect(result.values[0][0], 1.0);
      expect(result.values[1][1], 1.0);
    });

    test('должен вычислить корреляцию -1.0 для идеально отрицательной связи', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [10.0, 8.0, 6.0, 4.0, 2.0];
      final columns = [
        x.map((e) => e as double?).toList(),
        y.map((e) => e as double?).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      final corr = result.values[0][1];

      expect(corr, closeTo(-1.0, 1e-6));
    });

    test('должен вычислить корреляцию близкую к 0 для независимых данных', () {
      // Данные с теоретической корреляцией 0
      // x: 1 2 3 4 5; y: 1 2 1 2 1
      // Сумма произведений отклонений = 0
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [1.0, 2.0, 1.0, 2.0, 1.0];
      final columns = [
        x.map((e) => e as double?).toList(),
        y.map((e) => e as double?).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      final corr = result.values[0][1];

      expect(corr, closeTo(0.0, 1e-6));
    });

    test('должен корректно обрабатывать null значения (listwise deletion)', () {
      final x = [1.0, 2.0, null, 4.0, 5.0];
      final y = [2.0, null, 6.0, 8.0, 10.0];
      final columns = [
        x.map((e) => e).toList(),
        y.map((e) => e).toList(),
      ];

      // Только пары (1,2) и (4,8) и (5,10) -> идеальная корреляция
      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      final corr = result.values[0][1];

      expect(corr, closeTo(1.0, 1e-6));
    });

    test('должен возвращать 0.0, если после удаления null осталось меньше 2 пар', () {
      final x = [1.0, null, null];
      final y = [2.0, 3.0, null];
      final columns = [
        x.map((e) => e).toList(),
        y.map((e) => e).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      final corr = result.values[0][1];

      expect(corr, 0.0);
    });

    test('должен возвращать пустую матрицу при менее чем 2 столбцах', () {
      final columns = [
        [1.0, 2.0, 3.0].map((e) => e as double?).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      expect(result.rowLabels.isEmpty, true);
      expect(result.columnLabels.isEmpty, true);
      expect(result.values.isEmpty, true);
    });

    test('должен корректно устанавливать имена столбцов', () {
      final columns = [
        [1.0, 2.0, 3.0].map((e) => e as double?).toList(),
        [4.0, 5.0, 6.0].map((e) => e as double?).toList(),
      ];
      final names = ['Возраст', 'Доход'];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns, columnNames: names);

      expect(result.rowLabels, names);
      expect(result.columnLabels, names);
    });

    test('должен вычислять корреляцию для реальных данных с известным результатом', () {
      // Рост (x) и вес (y)
      final x = [150.0, 160.0, 170.0, 180.0, 190.0];
      final y = [55.0, 65.0, 70.0, 85.0, 95.0];
      final columns = [
        x.map((e) => e as double?).toList(),
        y.map((e) => e as double?).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      final corr = result.values[0][1];

      // Рассчитано вручную: r = 1000 / sqrt(1000 * 1020) ≈ 0.9901475
      expect(corr, closeTo(0.9901475, 1e-6));
    });

    test('симметричность матрицы корреляции', () {
      final x = [1.0, 2.0, 3.0, 4.0];
      final y = [4.0, 3.0, 2.0, 1.0];
      final z = [2.0, 4.0, 6.0, 8.0];
      final columns = [
        x.map((e) => e as double?).toList(),
        y.map((e) => e as double?).toList(),
        z.map((e) => e as double?).toList(),
      ];

      final result = HeatmapDataBuilder.pearsonCorrelation(columns);
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          expect(result.values[i][j], closeTo(result.values[j][i], 1e-6));
        }
      }
    });
  });
}