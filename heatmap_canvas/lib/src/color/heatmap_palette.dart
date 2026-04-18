import 'dart:ui';

import 'package:flutter/material.dart';

/// {@template heatmap_palette}
/// Доступные типы палитр для тепловой карты корреляции.
/// {@endtemplate}
enum HeatmapPalette {
  /// Красно-синяя палитра — классическая для корреляционных матриц
  redBlue,
  
  /// Палитра Red-Yellow-Green — от красного (отрицательная корреляция) к зелёному (положительная корреляция)
  redYellowGreen,

  /// Палитра Yellow-Orange-Red — от жёлтого (отрицательная корреляция) к красному (положительная корреляция)
  yellowOrangeRed,

  /// Палитра Viridis — научная, воспринимается одинаково в ч/б печати
  viridis,

  /// Палитра Inferno — яркая, с хорошей контрастностью для слабовидящих
  inferno,
  
  /// Палитра Magma — тёмная, с акцентом на высокие значения
  magma,

  /// Палитра Plasma — яркая, с акцентом на низкие значения
  plasma,

  /// Палитра Blues — градиент от светло-голубого к тёмно-синему
  blues,

  /// Палитра Greens — градиент от светло-зелёного к тёмно-зелёному
  greens,

  /// Палитра CoolWarm — мягкий градиент от холодных к тёплым тонам
  coolWarm,

  /// Палитра Teal-Orange — от бирюзового (отрицательная корреляция) к оранжево-жёлтому (положительная корреляция)
  tealOrange,

  custom
}

/// {@template heatmap_palette_factory}
/// Фабрика для создания палитр цветов тепловой карты.
/// {@endtemplate}
class HeatmapPaletteFactory {
  /// {@macro heatmap_palette_factory}
  /// 
  /// Принимает:
  /// - [palette] — тип желаемой палитры
  /// 
  /// Возвращает:
  /// - [List<Color>] — список цветов, составляющих палитру
  static List<Color> baseColors(HeatmapPalette palette, {List<Color>? customColors}) {
    switch (palette) {
      case HeatmapPalette.redBlue:
        return [
          const Color(0xFF08306B), // тёмно-синий
          const Color(0xFF2171B5), // синий
          const Color(0xFF6BAED6), // голубой
          const Color(0xFFE0E0E0), // серый (нейтральный)
          const Color(0xFFFB6A4A), // светло-красный
          const Color(0xFFDE2D26), // красный
          const Color(0xFFA50F15), // тёмно-красный
        ];

      case HeatmapPalette.viridis:
        return [
          const Color(0xFF440154), // фиолетовый
          const Color(0xFF3B528B), // сине-фиолетовый
          const Color(0xFF21918C), // бирюзовый
          const Color(0xFF5DC863), // зелёный
          const Color(0xFFFDE725), // жёлтый
        ];

      case HeatmapPalette.coolWarm:
        return [
          const Color(0xFF3B4CC0), // синий
          const Color(0xFF7788E8), // светло-синий
          const Color(0xFFDDDDDD), // серый (нейтральный)
          const Color(0xFFF4A582), // светло-оранжевый
          const Color(0xFFD73027), // красно-оранжевый
        ];

      case HeatmapPalette.redYellowGreen:
        return [
          const Color(0xFFD73027), // красный
          const Color(0xFFF46D43), // оранжевый
          const Color(0xFFE0E0E0), // жёлтый
          const Color(0xFF66BD63), // светло-зелёный
          const Color(0xFF1A9850), // зелёный
        ];

      case HeatmapPalette.yellowOrangeRed:
        return [
          const Color(0xFFFFE082), // жёлтый
          const Color(0xFFF46D43), // оранжевый
          const Color(0xFFD73027), // красный
        ];
      
      case HeatmapPalette.inferno:
        return [
          Color(0xFF000004),
          Color(0xFF420A68),
          Color(0xFF932667), 
          Color(0xFFDD513A), 
          Color(0xFFfdae61), 
          Color(0xFFfca636), 
          Color(0xFFfc8961), 
          Color(0xFFfde725)
        ];

      case HeatmapPalette.magma:
        return [
          Color(0xFF000004), 
          Color(0xFF170F1F), 
          Color(0xFF3B0F6F), 
          Color(0xFF711F81), 
          Color(0xFFB73779), 
          Color(0xFFFC8961), 
          Color(0xFFFCCB6C), 
          Color(0xFFfde725)
        ];

      case HeatmapPalette.plasma:
        return [
          Color(0xFF0D0887), 
          Color(0xFF46039F), 
          Color(0xFF7201A8), 
          Color(0xFF9C179E), 
          Color(0xFFBD3786), 
          Color(0xFFD8576B), 
          Color(0xFFED7953), 
          Color(0xFFfb9f3a), 
          Color(0xFFf0f921)
        ];

      case HeatmapPalette.blues:
        return [
          const Color(0xFFDEEBF7), // светло-голубой
          const Color(0xFF9ECAE1), // голубой
          const Color(0xFF3182BD), // синий
          const Color(0xFF08519C), // тёмно-синий
        ];

      case HeatmapPalette.greens:
        return [
          const Color(0xFFE5F5E0), // светло-зелёный
          const Color(0xFFA1D99B), // зелёный
          const Color(0xFF31A354), // тёмно-зелёный
          const Color(0xFF006D2C), // очень тёмно-зелёный
        ];
      case HeatmapPalette.tealOrange:
        return [
          const Color(0xFF06D2C2), // rgb(6,210,194) — бирюзовый
          const Color(0xFFFFFFFF), // белый
          const Color(0xFFFFB70B), // rgb(255,183,11) — оранжево-жёлтый
        ];

      case HeatmapPalette.custom:
        if (customColors == null || customColors.isEmpty) {
          throw ArgumentError('customColors must be provided for HeatmapPalette.custom');
        }
        return customColors;
    }
  }
}