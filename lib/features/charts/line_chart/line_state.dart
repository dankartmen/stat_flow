import '../chart_state.dart';

enum LineType { straight, curved, step }

/// {@template line_state}
/// Состояние линейного графика для системы плагинов
/// 
/// Хранит настройки отображения линейного графика:
/// - [columnName] — имя выбранной числовой колонки для оси Y
/// - [showMarkers] — показывать маркеры на точках
/// - [showGridLines] — показывать сетку
/// - [lineType] — прямая / сглаженная (Spline) / ступенчатая
/// - [lineWidth], [markerSize], [isDashed] — визуальная кастомизация
/// - [showDataLabels], [showTrendline], [trackballEnabled] — современные фичи
/// 
/// {@endtemplate}
class LineState extends ChartState {
  /// Имя выбранной числовой колонки для оси Y
  String? columnName;
  
  /// Показывать маркеры на точках
  bool showMarkers;
  
  /// Показывать сетку
  bool showGridLines;

  /// Тип линии: прямая, сглаженная или ступенчатая
  LineType lineType;

  /// Толщина линии
  double lineWidth;

  /// Размер маркеров
  double markerSize;

  /// Пунктирная линия
  bool isDashed;

  /// Показывать подписи значений на точках
  bool showDataLabels;

  /// Показывать трендлайн
  bool showTrendline;

  /// Включить трекбол для отображения значений при наведении
  bool trackballEnabled;

  bool animationEnabled;

  /// {@macro line_state}
  LineState({
    this.columnName,
    this.showMarkers = true,
    this.showGridLines = true,
    this.lineType = LineType.straight,
    this.lineWidth = 2.5,
    this.markerSize = 6.0,
    this.isDashed = false,
    this.showDataLabels = false,
    this.showTrendline = false,
    this.trackballEnabled = true,
    this.animationEnabled = true,
  });

  @override
  LineState copyWith({
    String? columnName,
    bool? showMarkers,
    bool? showGridLines,
    LineType? lineType,
    double? lineWidth,
    double? markerSize,
    bool? isDashed,
    bool? showDataLabels,
    bool? showTrendline,
    bool? trackballEnabled,
    bool? animationEnabled,
  }) {
    return LineState(
      columnName: columnName ?? this.columnName,
      showMarkers: showMarkers ?? this.showMarkers,
      showGridLines: showGridLines ?? this.showGridLines,
      lineType: lineType ?? this.lineType,
      lineWidth: lineWidth ?? this.lineWidth,
      markerSize: markerSize ?? this.markerSize,
      isDashed: isDashed ?? this.isDashed,
      showDataLabels: showDataLabels ?? this.showDataLabels,
      showTrendline: showTrendline ?? this.showTrendline,
      trackballEnabled: trackballEnabled ?? this.trackballEnabled,
      animationEnabled: animationEnabled ?? this.animationEnabled,
    );
  }

  @override
  LineState withField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric || type == ColumnType.dateTime) {
      return copyWith(columnName: columnName);
    }
    return this;
  }
}