import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/src/builder/heatmap_data_builder.dart';

void main() {
  test('Корреляция между числовой и категориальной колонкой должна иметь правильный знак', () {
    // Числовая колонка
    final numericValues = [1.0, 2.0, 3.0, 4.0, 5.0];
    // Категориальная колонка, где коды идут в том же порядке (положительная связь)
    final categoricalRaw = ['A', 'B', 'C', 'D', 'E'];
    // Кодируем вручную в правильном порядке (не по порядку появления, а по возрастанию)
    final codeMap = {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4};
    final encoded = categoricalRaw.map((e) => codeMap[e]!.toDouble()).toList();

    final columns = [
      numericValues.map((e) => e as double?).toList(),
      encoded.map((e) => e as double?).toList(),
    ];

    final result = HeatmapDataBuilder.pearsonCorrelation(columns);
    final corr = result.values[0][1];

    // Корреляция должна быть положительной и очень близкой к 1
    expect(corr, greaterThan(0.9));
    expect(corr, closeTo(1.0, 1e-6));
  });

  test('Перестановка кодов должна изменить знак корреляции на противоположный', () {
    final numericValues = [1.0, 2.0, 3.0, 4.0, 5.0];
    final categoricalRaw = ['A', 'B', 'C', 'D', 'E'];
    // Кодируем в обратном порядке (отрицательная связь)
    final codeMap = {'A': 4, 'B': 3, 'C': 2, 'D': 1, 'E': 0};
    final encoded = categoricalRaw.map((e) => codeMap[e]!.toDouble()).toList();

    final columns = [
      numericValues.map((e) => e as double?).toList(),
      encoded.map((e) => e as double?).toList(),
    ];

    final result = HeatmapDataBuilder.pearsonCorrelation(columns);
    final corr = result.values[0][1];

    // Корреляция должна быть отрицательной и близкой к -1
    expect(corr, lessThan(-0.9));
    expect(corr, closeTo(-1.0, 1e-6));
  });
}