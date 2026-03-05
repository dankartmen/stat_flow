import 'package:flutter/material.dart';

import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';

/// {@template heatmap_controls}
/// Панель управления для настройки отображения тепловой карты.
/// {@endtemplate}
class HeatmapControls extends StatelessWidget {
  /// Режим отображения верхнего треугольника
  final bool upperTriangle;
  
  /// Коллбек при изменении режима треугольника
  final ValueChanged<bool> onUpperTriangleChanged;

  /// Количество сегментов для дискретного режима
  final int segments;
  
  /// Коллбек при изменении количества сегментов
  final ValueChanged<int> onSegmentsChanged;

  /// Выбранная цветовая палитра
  final HeatmapPalette palette;
  
  /// Коллбек при изменении палитры
  final ValueChanged<HeatmapPalette> onPaletteChanged;

  /// Режим отображения цветов (дискретный/градиент)
  final HeatmapColorMode colorMode;
  
  /// Коллбек при изменении режима цветов
  final ValueChanged<HeatmapColorMode> onColorModeChanged;

  /// Включена ли кластеризация
  final bool clusterEnabled;
  
  /// Коллбек при нажатии на кнопку кластеризации
  final VoidCallback onClusterPressed;

  /// {@macro heatmap_controls}
  const HeatmapControls({
    super.key,
    required this.upperTriangle,
    required this.onUpperTriangleChanged,
    required this.segments,
    required this.onSegmentsChanged,
    required this.palette,
    required this.onPaletteChanged,
    required this.colorMode,
    required this.onColorModeChanged,
    required this.clusterEnabled,
    required this.onClusterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [

        // Выбор палитры
        DropdownButton<HeatmapPalette>(
          value: palette,
          items: HeatmapPalette.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(p.name),
            );
          }).toList(),
          onChanged: (v) => onPaletteChanged(v!),
        ),

        // Выбор режима цвета
        DropdownButton<HeatmapColorMode>(
          value: colorMode,
          items: HeatmapColorMode.values.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(m.name),
            );
          }).toList(),
          onChanged: (v) => onColorModeChanged(v!),
        ),

        // Количество сегментов (только для дискретного режима)
        if (colorMode == HeatmapColorMode.discrete)
          DropdownButton<int>(
            value: segments,
            items: const [
              DropdownMenuItem(value: 5, child: Text("0.4")),
              DropdownMenuItem(value: 10, child: Text("0.2")),
              DropdownMenuItem(value: 20, child: Text("0.1")),
            ],
            onChanged: (v) => onSegmentsChanged(v!),
          ),

        // Переключатель режима верхнего треугольника
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: upperTriangle,
              onChanged: (v) => onUpperTriangleChanged(v!),
            ),
            const Text("Верхний треугольник"),
          ],
        ),

        // Кнопка кластеризации
        ElevatedButton.icon(
          onPressed: onClusterPressed,
          icon: Icon(
            clusterEnabled
                ? Icons.check
                : Icons.account_tree,
          ),
          label: Text(
            clusterEnabled
                ? "Кластеризация включена"
                : "Кластеризовать",
          ),
        ),
      ],
    );
  }
}