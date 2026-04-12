import 'package:heatmap_canvas/heatmap.dart';
import 'package:stat_flow/features/charts/chart_state.dart';


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
/// - Параметры нормализации, сортировки, агрегации и процентов
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
  
  /// Имя колонки для X оси (если null — режим корреляции всех числовых)
  String? xColumn;

  /// Имя колонки для Y оси (если null — режим корреляции всех числовых)
  String? yColumn;

  /// Тип агрегации, когда Y колонка числовая
  AggregationType aggregationType;

  /// Режим отображения значений в процентах
  PercentageMode percentageMode;
  
  /// Использовать ли корреляцию всех числовых полей (вместо выбора осей)
  bool useCorrelation;

  /// {@macro heatmap_state}
  HeatmapState({
    this.useCorrelation = true,
    this.showAxisLabels = false,
    this.showValues = true,
    this.palette = HeatmapPalette.redBlue,
    this.segments = 10,
    this.triangleMode = false,
    this.clusterEnabled = false,
    this.colorMode = HeatmapColorMode.discrete,
    this.normalizeMode = NormalizeMode.none,
    this.sortX = SortMode.none,
    this.sortY = SortMode.none,
    this.xColumn,
    this.yColumn,
    this.aggregationType = AggregationType.count,
    this.percentageMode = PercentageMode.none,
  });


  @override
  HeatmapState copyWith({
    HeatmapPalette? palette,
    int? segments,
    HoverRange? hoverRange,
    bool? showAxisLabels,
    bool? showValues,
    bool? triangleMode,
    bool? clusterEnabled,
    HeatmapColorMode? colorMode,
    NormalizeMode? normalizeMode,
    SortMode? sortX,
    SortMode? sortY,
    ColorScaleType? scaleType,
    String? xColumn,
    String? yColumn,
    AggregationType? aggregationType,
    PercentageMode? percentageMode,
    bool? useCorrelation,
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
      xColumn: xColumn ?? this.xColumn,
      yColumn: yColumn ?? this.yColumn,
      aggregationType: aggregationType ?? this.aggregationType,
      percentageMode: percentageMode ?? this.percentageMode,
      useCorrelation: useCorrelation ?? this.useCorrelation,

    );
  }
}