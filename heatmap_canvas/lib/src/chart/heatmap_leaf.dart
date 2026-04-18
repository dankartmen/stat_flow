import 'package:flutter/material.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import 'render_heatmap.dart';

/// {@template heatmap_leaf}
/// Низкоуровневый виджет для рендеринга тепловой карты.
///
/// Является обёрткой над [RenderHeatmap] и использует [LeafRenderObjectWidget]
/// для минимизации накладных расходов на виджеты.
/// Весь рендеринг, включая отрисовку ячеек, осей и обработку событий,
/// выполняется в [RenderHeatmap].
/// {@endtemplate}
class HeatmapLeaf extends LeafRenderObjectWidget {
  /// Основные данные тепловой карты (текущее состояние).
  final HeatmapData data;

  /// Целевые данные для анимации перехода между состояниями.
  final HeatmapData targetData;

  /// Значение анимации от 0.0 до 1.0, где:
  /// - 0.0 — отображается [data]
  /// - 1.0 — отображается [targetData]
  final double animationValue;

  /// Конфигурация внешнего вида и поведения тепловой карты.
  final HeatmapConfig config;

  /// Внешний диапазон подсветки (например, при синхронизации с другой тепловой картой).
  final HoverRange? hoverRange;

  const HeatmapLeaf({
    super.key,
    required this.data,
    required this.targetData,
    required this.animationValue,
    required this.config,
    this.hoverRange,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHeatmap(
      buildContext: context,
      data: data,
      targetData: targetData,
      animationValue: animationValue,
      config: config,
      textScaler: MediaQuery.textScalerOf(context),
      externalHoverRange: hoverRange,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderHeatmap renderObject) {
    // Определяем, изменилась ли цветовая схема для оптимизации пересоздания мапперов
    final colorChanged = renderObject.config.palette != config.palette ||
        renderObject.config.colorMode != config.colorMode ||
        renderObject.config.customPaletteColors != config.customPaletteColors ||
        renderObject.config.segments != config.segments;

    renderObject
      ..data = data
      ..targetData = targetData
      ..animationValue = animationValue
      ..config = config
      ..textScaler = MediaQuery.textScalerOf(context)
      ..externalHoverRange = hoverRange;

    // Обновляем мапперы цветов только при реальном изменении цветовой схемы
    if (colorChanged) {
      renderObject.updateMappers(config, data);
    }
  }
}