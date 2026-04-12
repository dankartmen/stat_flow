import '../../heatmap.dart';

/// Информация о точке на легенде для кастомного тултипа
class LegendTooltipInfo {
  /// Точное значение на шкале под курсором
  final double value;

  /// Минимальное значение сегмента (только для дискретного режима)
  final double? segmentMin;

  /// Максимальное значение сегмента (только для дискретного режима)
  final double? segmentMax;

  /// Индекс сегмента (только для дискретного режима)
  final int? segmentIndex;

  /// Режим цветовой шкалы
  final HeatmapColorMode colorMode;

  const LegendTooltipInfo({
    required this.value,
    this.segmentMin,
    this.segmentMax,
    this.segmentIndex,
    required this.colorMode,
  });

  /// Удобный геттер для проверки дискретного режима
  bool get isDiscrete => colorMode == HeatmapColorMode.discrete;
}