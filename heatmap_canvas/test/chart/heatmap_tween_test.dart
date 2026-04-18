import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/src/model/heatmap_data.dart';
import 'package:heatmap_canvas/src/widgets/heatmap.dart';

void main() {
  group('HeatmapDataTween', () {
    final begin = HeatmapData(
      rowLabels: ['R1'],
      columnLabels: ['C1', 'C2'],
      values: [[0.0, 1.0]],
    );
    final end = HeatmapData(
      rowLabels: ['R1'],
      columnLabels: ['C1', 'C2'],
      values: [[10.0, 20.0]],
    );

    test('lerp at t=0 returns begin', () {
      final tween = HeatmapDataTween(begin: begin, end: end);
      final result = tween.lerp(0.0);
      expect(result.values[0][0], closeTo(0.0, 1e-6));
      expect(result.values[0][1], closeTo(1.0, 1e-6));
    });

    test('lerp at t=1 returns end', () {
      final tween = HeatmapDataTween(begin: begin, end: end);
      final result = tween.lerp(1.0);
      expect(result.values[0][0], closeTo(10.0, 1e-6));
      expect(result.values[0][1], closeTo(20.0, 1e-6));
    });

    test('lerp at t=0.5 interpolates', () {
      final tween = HeatmapDataTween(begin: begin, end: end);
      final result = tween.lerp(0.5);
      expect(result.values[0][0], closeTo(5.0, 1e-6));
      expect(result.values[0][1], closeTo(10.5, 1e-6));
    });

    test('if sizes mismatch, returns end', () {
      final differentSize = HeatmapData(
        rowLabels: ['R1', 'R2'],
        columnLabels: ['C1'],
        values: [[0.0], [1.0]],
      );
      final tween = HeatmapDataTween(begin: begin, end: differentSize);
      expect(tween.lerp(0.5), same(differentSize));
    });
  });
}