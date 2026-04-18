import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:heatmap_canvas/src/color/heatmap_palette.dart';
import 'package:heatmap_canvas/src/model/heatmap_config.dart';
import 'package:heatmap_canvas/src/model/heatmap_data.dart';
import 'package:heatmap_canvas/src/widgets/heatmap.dart';


void main() {
  testGoldens('Heatmap renders correctly', (tester) async {
    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: Heatmap(
                data: HeatmapData(
                  rowLabels: ['A', 'B'],
                  columnLabels: ['X', 'Y'],
                  values: [
                    [0.1, 0.5],
                    [0.8, 0.3],
                  ],
                ),
                config: const HeatmapConfig(
                  showValues: true,
                  palette: HeatmapPalette.blues,
                ),
              ),
            ),
          ),
        ),
      ),
      surfaceSize: const Size(400, 400),
    );
    await screenMatchesGolden(tester, 'heatmap_basic');
  });

  testGoldens('Heatmap triangle mode', (tester) async {
    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: Heatmap(
                data: HeatmapData(
                  rowLabels: ['A', 'B', 'C'],
                  columnLabels: ['A', 'B', 'C'],
                  values: [
                    [1.0, 0.5, 0.2],
                    [0.5, 1.0, 0.8],
                    [0.2, 0.8, 1.0],
                  ],
                ),
                config: const HeatmapConfig(triangleMode: true),
              ),
            ),
          ),
        ),
      ),
      surfaceSize: const Size(400, 400),
    );
    await screenMatchesGolden(tester, 'heatmap_triangle');
  });
}