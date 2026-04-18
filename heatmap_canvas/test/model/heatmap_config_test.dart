import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/src/color/heatmap_color_mapper.dart';
import 'package:heatmap_canvas/src/color/heatmap_palette.dart';
import 'package:heatmap_canvas/src/model/heatmap_config.dart';
import 'package:heatmap_canvas/src/model/touch_data.dart';

void main() {
  group('HeatmapConfig', () {
    test('default values', () {
      const config = HeatmapConfig();
      expect(config.palette, HeatmapPalette.redBlue);
      expect(config.colorMode, HeatmapColorMode.discrete);
      expect(config.segments, 10);
      expect(config.showValues, false);
    });

    test('copyWith updates fields', () {
      const original = HeatmapConfig(segments: 5);
      final updated = original.copyWith(segments: 8, showValues: true);
      expect(updated.segments, 8);
      expect(updated.showValues, true);
      expect(updated.palette, original.palette);
    });

    test('Equatable compares correctly', () {
      const config1 = HeatmapConfig(segments: 5);
      const config2 = HeatmapConfig(segments: 5);
      const config3 = HeatmapConfig(segments: 10);
      expect(config1, config2);
      expect(config1, isNot(config3));
    });
  });

  group('HeatmapAxisData', () {
    test('copyWith and Equatable', () {
      const axis = HeatmapAxisData(showLabels: true);
      final copy = axis.copyWith(showLabels: false);
      expect(copy.showLabels, false);
      expect(axis == copy, false);
    });
  });

  group('HeatmapTouchData', () {
    test('defaults and copyWith', () {
      const touch = HeatmapTouchData();
      expect(touch.enabled, true);
      final updated = touch.copyWith(enabled: false);
      expect(updated.enabled, false);
    });
  });
}