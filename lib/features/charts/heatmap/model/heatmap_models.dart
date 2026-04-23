import 'package:flutter/material.dart';

/// {@template heatmap_tooltip_style}
/// Стиль для кастомного тултипа с прогресс-баром.
/// 
/// Позволяет настроить цвета для положительных/отрицательных значений,
/// фон, стили текста и ширину тултипа.
/// {@endtemplate}
class HeatmapTooltipStyle {
  /// Цвет для положительных значений (или значений ≥0).
  final Color positiveColor;

  /// Цвет для отрицательных значений.
  final Color negativeColor;

  /// Цвет фона тултипа.
  final Color backgroundColor;

  /// Стиль текста заголовка (названия строки и колонки).
  final TextStyle labelStyle;

  /// Стиль текста значения.
  final TextStyle valueStyle;

  /// Ширина тултипа в пикселях.
  final double width;

  /// {@macro heatmap_tooltip_style}
  const HeatmapTooltipStyle({
    this.positiveColor = Colors.green,
    this.negativeColor = Colors.red,
    this.backgroundColor = Colors.white,
    this.labelStyle = const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    this.valueStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    this.width = 240,
  });
}