import 'package:flutter/material.dart';
import '../model/legend_tooltip_info.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';

/// Режим нормализации
enum NormalizeMode { none, row, column, total }

/// Режим сортировки
enum SortMode { none, alphabetic, byValueAsc, byValueDesc }

/// Режим агрегации (для справки, может использоваться при подготовке данных)
enum AggregationType { count, sum, avg, min, max, median }

/// Режим отображения в процентах
enum PercentageMode { none, row, column, total }

/// Конфигурация отображения тепловой карты (immutable)
class HeatmapConfig {
  // --- Цвет ---
  final HeatmapPalette palette;
  final HeatmapColorMode colorMode;
  final int segments;

  // --- Сортировка и кластеризация ---
  final SortMode sortX;
  final SortMode sortY;
  final bool clusterEnabled; // будет применяться пользователем через Transformer

  // --- Отображение ---
  final bool showAxisLabels;
  final bool showValues;
  final bool triangleMode;

  // --- Масштаб ---
  final double minScale;
  final double maxScale;

  // --- Кастомизация ---
  /// Форматирование значения в ячейке (если null — используется стандартное)
  final String Function(double value)? cellValueFormatter;

  /// Форматирование подписи оси (если null — возвращается исходная строка)
  final String Function(String label)? axisLabelFormatter;

  /// Билдер кастомного тултипа. Если null — тултип не показывается.
  final Widget Function(BuildContext context, HeatmapCell cell)? cellTooltipBuilder;

  /// Билдер кастомного тултипа для легенды.
  /// Принимает текущее значение (или null, если курсор вне легенды) и контекст.
  /// Если null — используется стандартный тултип.
  final Widget Function(BuildContext context, LegendTooltipInfo?)? legendTooltipBuilder;


  /// Стиль текста подписей осей
  final TextStyle? axisTextStyle;

  /// Угол поворота подписей столбцов в радианах (по умолчанию -0.6)
  final double axisLabelRotation;

  const HeatmapConfig({
    this.palette = HeatmapPalette.redBlue,
    this.colorMode = HeatmapColorMode.discrete,
    this.segments = 10,
    this.sortX = SortMode.none,
    this.sortY = SortMode.none,
    this.clusterEnabled = false,
    this.showAxisLabels = true,
    this.showValues = false,
    this.triangleMode = false,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.cellValueFormatter,
    this.axisLabelFormatter,
    this.cellTooltipBuilder,
    this.legendTooltipBuilder,
    this.axisTextStyle,
    this.axisLabelRotation = -0.6, // небольшой наклон по умолчанию
  });

  HeatmapConfig copyWith({
    HeatmapPalette? palette,
    HeatmapColorMode? colorMode,
    int? segments,
    SortMode? sortX,
    SortMode? sortY,
    bool? clusterEnabled,
    bool? showAxisLabels,
    bool? showValues,
    bool? triangleMode,
    double? minScale,
    double? maxScale,
    String Function(double value)? cellValueFormatter,
    Widget Function(BuildContext context, HeatmapCell cell)? cellTooltipBuilder,
    Widget Function(BuildContext context, LegendTooltipInfo? value)? legendTooltipBuilder,
    TextStyle? axisTextStyle,
    double? axisLabelRotation,
  }) {
    return HeatmapConfig(
      palette: palette ?? this.palette,
      colorMode: colorMode ?? this.colorMode,
      segments: segments ?? this.segments,
      sortX: sortX ?? this.sortX,
      sortY: sortY ?? this.sortY,
      clusterEnabled: clusterEnabled ?? this.clusterEnabled,
      showAxisLabels: showAxisLabels ?? this.showAxisLabels,
      showValues: showValues ?? this.showValues,
      triangleMode: triangleMode ?? this.triangleMode,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      cellValueFormatter: cellValueFormatter ?? this.cellValueFormatter,
      cellTooltipBuilder: cellTooltipBuilder ?? this.cellTooltipBuilder,
      legendTooltipBuilder: legendTooltipBuilder ?? this.legendTooltipBuilder,
      axisTextStyle: axisTextStyle ?? this.axisTextStyle,
      axisLabelRotation: axisLabelRotation ?? this.axisLabelRotation,
    );
  }
}

/// Данные о ячейке для тултипа
class HeatmapCell {
  final double value;
  final String rowLabel;
  final String colLabel;
  final int rowIndex;
  final int colIndex;

  HeatmapCell({
    required this.value,
    required this.rowLabel,
    required this.colLabel,
    required this.rowIndex,
    required this.colIndex,
  });
}