// heatmap_section.dart

import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/chart_conteiner.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_controls.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/correlation_matrix.dart';
import 'heatmap_view.dart';

/// {@template heatmap_section}
/// Секция страницы, содержащая тепловую карту корреляции с заголовком,
/// элементами управления и описанием.
///
/// Предоставляет пользовательский интерфейс для:
/// - Выбора цветовой палитры
/// - Настройки количества сегментов (для дискретного режима)
/// - Переключения между верхним треугольником и полной матрицей
/// - Включения/выключения кластеризации
/// - Переключения между градиентным и дискретным режимами отображения
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

  /// Выбранная цветовая палитра
  HeatmapPalette palette = HeatmapPalette.redBlue;

  /// Количество сегментов для дискретного режима
  int segments = 10;

  /// Режим отображения только верхнего треугольника
  bool triangleMode = false;

  /// Включена ли кластеризация
  bool clusterEnabled = false;

  /// Режим отображения цветов (дискретный/градиентный)
  HeatmapColorMode colorMode = HeatmapColorMode.discrete;

  @override
  Widget build(BuildContext context) {
    return ChartContainer(
      title: "Тепловая матрица корреляций",

      // Панель управления над графиком
      controls: HeatmapControls(
        palette: palette,
        segments: segments,
        upperTriangle: triangleMode,
        clusterEnabled: clusterEnabled,
        colorMode: colorMode,

        // Колбэки для обновления состояния при взаимодействии пользователя
        onPaletteChanged: (p) => setState(() => palette = p),
        onSegmentsChanged: (s) => setState(() => segments = s),
        onUpperTriangleChanged: (v) => setState(() => triangleMode = v),
        onClusterPressed: () => setState(() => clusterEnabled = !clusterEnabled),
        onColorModeChanged: (m) => setState(() => colorMode = m),
      ),

      // Виджет тепловой карты
      child: HeatmapView(
        matrix: widget.matrix,
        palette: palette,
        segments: segments,
        triangleMode: triangleMode,
        clusterEnabled: clusterEnabled,
        colorMode: colorMode,
      ),
    );
  }
}