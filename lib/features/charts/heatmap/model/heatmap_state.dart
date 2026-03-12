import '../../chart_state.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';

/// {@template heatmap_state}
/// Состояние тепловой карты для системы плагинов
/// 
/// Хранит все настройки отображения тепловой карты:
/// - Выбранная цветовая палитра
/// - Количество сегментов для дискретного режима
/// - Режим отображения подписей осей
/// - Режим отображения значений в ячейках
/// - Режим верхнего треугольника
/// - Включение кластеризации
/// - Режим раскраски (дискретный/градиентный)
/// 
/// Наследуется от [ChartState] для интеграции с системой плагинов.
/// {@endtemplate}
class HeatmapState extends ChartState {
  /// Выбранная цветовая палитра
  HeatmapPalette palette;

  /// Количество сегментов для дискретного режима
  int segments;

  /// Отображать ли подписи осей
  bool showAxisLabels;

  /// Отображать ли значения внутри ячеек
  bool showValues;

  /// Режим отображения только верхнего треугольника
  bool triangleMode;

  /// Включена ли кластеризация
  bool clusterEnabled;

  /// Режим раскраски (дискретный/градиентный)
  HeatmapColorMode colorMode;

  /// {@macro heatmap_state}
  HeatmapState({
    this.showAxisLabels = false,
    this.showValues = false,
    this.palette = HeatmapPalette.redBlue,
    this.segments = 10,
    this.triangleMode = false,
    this.clusterEnabled = false,
    this.colorMode = HeatmapColorMode.discrete,
  });
}