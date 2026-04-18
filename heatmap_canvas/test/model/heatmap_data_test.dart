import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/heatmap.dart';


void main() {
  late HeatmapData testData;

  setUp(() {
    testData = HeatmapData(
      rowLabels: ['R1', 'R2', 'R3'],
      columnLabels: ['C1', 'C2', 'C3'],
      values: [
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, 9.0],
      ],
    );
  });

  group('HeatmapData', () {
    test('min and max are calculated correctly', () {
      expect(testData.min, 1.0);
      expect(testData.max, 9.0);
    });

    test('normalize by row', () {
      final normalized = testData.normalize(NormalizeMode.row);
      // Row 1: 1+2+3=6 -> [1/6, 2/6, 3/6]
      expect(normalized.values[0][0], closeTo(1/6, 1e-6));
      expect(normalized.values[0][1], closeTo(2/6, 1e-6));
      expect(normalized.values[0][2], closeTo(3/6, 1e-6));
    });

    test('normalize by column', () {
      final normalized = testData.normalize(NormalizeMode.column);
      // Col 1: 1+4+7=12 -> [1/12, 4/12, 7/12]
      expect(normalized.values[0][0], closeTo(1/12, 1e-6));
      expect(normalized.values[1][0], closeTo(4/12, 1e-6));
      expect(normalized.values[2][0], closeTo(7/12, 1e-6));
    });

    test('normalize total', () {
      final normalized = testData.normalize(NormalizeMode.total);
      final total = 1+2+3+4+5+6+7+8+9; // 45
      expect(normalized.values[0][0], closeTo(1/45, 1e-6));
    });

    test('sort rows by value ascending', () {
      final sorted = testData.sortRows(SortMode.byValueAsc);
      // sums: R1=6, R2=15, R3=24 -> order: R1, R2, R3
      expect(sorted.rowLabels, ['R1', 'R2', 'R3']);
    });

    test('sort rows by value descending', () {
      final sorted = testData.sortRows(SortMode.byValueDesc);
      expect(sorted.rowLabels, ['R3', 'R2', 'R1']);
    });

    test('sort rows alphabetically', () {
      final data = HeatmapData(
        rowLabels: ['B', 'A', 'C'],
        columnLabels: ['C1'],
        values: [[1], [2], [3]],
      );
      final sorted = data.sortRows(SortMode.alphabetic);
      expect(sorted.rowLabels, ['A', 'B', 'C']);
    });

    test('sort columns similarly', () {
      final sorted = testData.sortCols(SortMode.byValueAsc);
      // sums: C1=12, C2=15, C3=18
      expect(sorted.columnLabels, ['C1', 'C2', 'C3']);
    });

    test('toPercentages row', () {
      final pct = testData.toPercentages(PercentageMode.row);
      expect(pct.values[0][0], closeTo(1/6*100, 1e-6));
    });

    test('copyWith создает новый экземпляр', () {
      final copy = testData.copyWith(rowLabels: ['A', 'B', 'C']); // правильная длина
      expect(copy.rowLabels, ['A', 'B', 'C']);
      expect(copy.columnLabels, testData.columnLabels);
      expect(copy.values, testData.values);
      expect(copy == testData, false);
    });

    

    test('Equatable works', () {
      final same = HeatmapData(
        rowLabels: ['R1', 'R2', 'R3'],
        columnLabels: ['C1', 'C2', 'C3'],
        values: [
          [1.0, 2.0, 3.0],
          [4.0, 5.0, 6.0],
          [7.0, 8.0, 9.0],
        ],
      );
      expect(testData, same);
    });
  });
}