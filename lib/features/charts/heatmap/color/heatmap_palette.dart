import 'dart:ui';

/// {@template heatmap_palette}
/// Доступные типы палитр для тепловой карты корреляции.
/// {@endtemplate}
enum HeatmapPalette {
  /// Красно-синяя палитра — классическая для корреляционных матриц
  redBlue,
  
  /// Палитра Viridis — научная, воспринимается одинаково в ч/б печати
  viridis,
  
  /// Палитра CoolWarm — мягкий градиент от холодных к тёплым тонам
  coolWarm,
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
  static List<Color> baseColors(HeatmapPalette palette) {
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
    }
  }
}