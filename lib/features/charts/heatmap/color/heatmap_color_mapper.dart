import 'package:flutter/material.dart';

import 'heatmap_palette.dart';

/// {@template heatmap_color_mapper}
/// Абстрактный класс для преобразования числовых значений корреляции
/// в цвета для отрисовки тепловой карты.
/// {@endtemplate}
abstract class HeatmapColorMapper {
  /// {@macro heatmap_color_mapper}
  /// 
  /// Принимает:
  /// - [value] — значение корреляции (обычно от -1 до 1)
  /// 
  /// Возвращает:
  /// - [Color] — цвет, соответствующий значению
  Color map(double value);
}

/// Режимы отображения цветов тепловой карты
enum HeatmapColorMode {
  /// Дискретный режим — значение попадает в один из заданных сегментов
  discrete,
  
  /// Градиентный режим — плавный переход между цветами
  gradient,
}

/// {@template discrete_color_mapper}
/// Маппер цветов с дискретным разбиением диапазона значений на сегменты.
/// {@endtemplate}
class DiscreteColorMapper implements HeatmapColorMapper {
  /// Минимальное значение диапазона
  final double min;
  
  /// Максимальное значение диапазона
  final double max;
  
  /// Количество сегментов разбиения
  final int segments;
  
  /// Базовые цвета для интерполяции палитры
  final List<Color> baseColors;

  /// Сгенерированная палитра цветов для каждого сегмента
  late final List<Color> _generatedColors;
  
  /// Шаг между сегментами
  late final double _step;

  /// {@macro discrete_color_mapper}
  DiscreteColorMapper({
    required this.min,
    required this.max,
    required this.segments,
    required this.baseColors,
  }) {
    _step = (max - min) / segments;
    _generatedColors = _generateColors();
  }

  @override
  Color map(double value) {
    final clamped = value.clamp(min, max);
    final index = ((clamped - min) / _step).floor();

    return _generatedColors[
        index.clamp(0, segments - 1)
    ];
  }

  /// Генерация цветов для всех сегментов на основе базовой палитры
  List<Color> _generateColors() {
    final result = <Color>[];

    for (int i = 0; i < segments; i++) {
      final t = i / (segments - 1);
      result.add(_interpolatePalette(t));
    }

    return result;
  }

  /// Интерполяция между цветами базовой палитры
  Color _interpolatePalette(double t) {
    final scaled = t * (baseColors.length - 1);
    final index = scaled.floor();
    final fraction = scaled - index;

    if (index >= baseColors.length - 1) {
      return baseColors.last;
    }

    return Color.lerp(
      baseColors[index],
      baseColors[index + 1],
      fraction,
    )!;
  }
}

/// {@template gradient_color_mapper}
/// Маппер цветов с плавным градиентным переходом между значениями.
/// {@endtemplate}
class GradientColorMapper implements HeatmapColorMapper {
  /// Палитра цветов для градиента
  final List<Color> palette;
  
  /// Минимальное значение диапазона
  final double min;
  
  /// Максимальное значение диапазона
  final double max;

  /// {@macro gradient_color_mapper}
  GradientColorMapper({
    required HeatmapPalette paletteType,
    this.min = -1,
    this.max = 1,
  }) : palette = HeatmapPaletteFactory.baseColors(paletteType);

  @override
  Color map(double value) {
    final normalized = ((value - min) / (max - min))
        .clamp(0.0, 1.0);

    return _interpolate(palette, normalized);
  }

  /// Интерполяция между цветами палитры
  static Color _interpolate(List<Color> colors, double t) {
    final scaled = t * (colors.length - 1);
    final index = scaled.floor();
    final remainder = scaled - index;

    if (index >= colors.length - 1) {
      return colors.last;
    }

    return Color.lerp(
      colors[index],
      colors[index + 1],
      remainder,
    )!;
  }
}