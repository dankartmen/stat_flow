import '../../chart_state.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';

enum NormalizeMode { none, row, column, total }
enum SortMode { none, alphabetic, byValueAsc, byValueDesc }


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

  /// Режим нормализации данных для отображения на тепловой карте
  NormalizeMode normalizeMode;

  /// Режим сортировки строк
  SortMode sortX;

  /// Режим сортировки столбцов
  SortMode sortY;

  /// Режим масштабирования цветовой шкалы
  ColorScaleType scaleType;

  /// Показывать ли проценты вместо абсолютных значений в ячейках
  bool showPercentage;
  
  /// {@macro heatmap_state}
  HeatmapState({
    this.showAxisLabels = false,
    this.showValues = false,
    this.palette = HeatmapPalette.redBlue,
    this.segments = 10,
    this.triangleMode = false,
    this.clusterEnabled = false,
    this.colorMode = HeatmapColorMode.discrete,
    this.normalizeMode = NormalizeMode.row,
    this.sortX = SortMode.none,
    this.sortY = SortMode.none,
    this.scaleType = ColorScaleType.linear,
    this.showPercentage = false,
  });


  @override
  HeatmapState copyWith({
    HeatmapPalette? palette,
    int? segments,
    bool? showAxisLabels,
    bool? showValues,
    bool? triangleMode,
    bool? clusterEnabled,
    HeatmapColorMode? colorMode,
    NormalizeMode? normalizeMode,
    SortMode? sortX,
    SortMode? sortY,
    ColorScaleType? scaleType,
    bool? showPercentage,
  }) {
    return HeatmapState(
      palette: palette ?? this.palette,
      segments: segments ?? this.segments,
      showAxisLabels: showAxisLabels ?? this.showAxisLabels,
      showValues: showValues ?? this.showValues,
      triangleMode: triangleMode ?? this.triangleMode,
      clusterEnabled: clusterEnabled ?? this.clusterEnabled,
      colorMode: colorMode ?? this.colorMode,
      normalizeMode: normalizeMode ?? this.normalizeMode,
      sortX: sortX ?? this.sortX,
      sortY: sortY ?? this.sortY,
      scaleType: scaleType ?? this.scaleType,
      showPercentage: showPercentage ?? this.showPercentage,
    );
  }
}