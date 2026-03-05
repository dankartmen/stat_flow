import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/chart_conteiner.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_controls.dart';

import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/correlation_matrix.dart';
import 'heatmap_view.dart';

/// {@template heatmap_section}
/// Секция страницы, содержащая тепловую карту корреляции с заголовком
/// и описанием.
/// {@endtemplate}
class HeatmapSection extends StatefulWidget {
  /// Матрица корреляции для отображения
  final CorrelationMatrix matrix;

  /// {@macro heatmap_section}
  const HeatmapSection({
    super.key,
    required this.matrix,
  });

  @override
  State<HeatmapSection> createState() => _HeatmapSectionState();
}

class _HeatmapSectionState extends State<HeatmapSection> {
  HeatmapPalette palette = HeatmapPalette.redBlue;
  int segments = 10;
  bool triangleMode = false;
  bool clusterEnabled = false;
  HeatmapColorMode colorMode = HeatmapColorMode.discrete;

  @override
  Widget build(BuildContext context) {
    return ChartContainer(
      title: "Тепловая матрица корреляций", 
      child: HeatmapView(matrix: widget.matrix),
    //   controls: HeatmapControls(
    //     palette: palette,
    //     segments: segments,
    //     upperTriangle: triangleMode,
    //     clusterEnabled: clusterEnabled,
    //     colorMode: colorMode, 

    //     onPaletteChanged: (p) => setState(() => palette = p),

    //     onSegmentsChanged: (s) => setState(() => segments = s),

    //     onUpperTriangleChanged: (v) => setState(() => triangleMode = v),

    //     onClusterPressed: () => setState(() => clusterEnabled = !clusterEnabled),

    //     onColorModeChanged: (m) => setState(() => colorMode = m),
    // ),
    );
  }
}