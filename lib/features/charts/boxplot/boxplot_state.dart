import 'package:syncfusion_flutter_charts/charts.dart';

import '../chart_state.dart';



/// {@template boxplot_state}
/// Состояние ящика с усами (box plot) для системы плагинов
/// 
/// Хранит настройки отображения ящика с усами:
/// - [columnName] — имя выбранной числовой колонки для анализа
/// - [showMean] — показывать ли на графике среднее значение
/// - [showOutliers] — показывать ли выбросы (outliers)
/// - [maxPoints] — максимальное количество точек для расчета статистики
/// - [boxPlotMode] — режим расчёта квартилей
/// - [boxWidth], [spacing], [borderWidth], [outlierSize] — визуальная кастомизация
/// - [showAllPoints] — показывать все точки (с джиттером)
/// Наследуется от [ChartState] для интеграции с системой плагинов.
/// {@endtemplate}
class BoxPlotState extends ChartState {
  /// Имя выбранной числовой колонки для отображения
  String? columnName;

  /// Показывать ли на графике среднее значение
  bool showMean;

  /// Показывать ли выбросы (outliers)
  bool showOutliers;

  /// Показывать все точки (джиттер)
  bool showAllPoints;

  /// Максимальное количество точек для расчёта и отображения
  int maxPoints;

  /// Режим расчёта box plot
  BoxPlotMode boxPlotMode;

  /// Ширина ящика (0.1–1.0)
  double boxWidth;

  /// Отступ между ящиками (для будущей поддержки нескольких серий)
  double spacing;

  /// Толщина границы
  double borderWidth;

  /// Размер маркеров выбросов
  double outlierSize;

  /// {@macro boxplot_state}
  BoxPlotState({
    this.columnName,
    this.showMean = true,
    this.showOutliers = true,
    this.showAllPoints = false,
    this.maxPoints = 5000,
    this.boxPlotMode = BoxPlotMode.normal,
    this.boxWidth = 0.6,
    this.spacing = 0.2,
    this.borderWidth = 2.0,
    this.outlierSize = 6.0,
  });

  @override
  BoxPlotState copyWith({
    String? columnName,
    bool? showMean,
    bool? showOutliers,
    bool? showAllPoints,
    int? maxPoints,
    BoxPlotMode? boxPlotMode,
    double? boxWidth,
    double? spacing,
    double? borderWidth,
    double? outlierSize,
  }) {
    return BoxPlotState(
      columnName: columnName ?? this.columnName,
      showMean: showMean ?? this.showMean,
      showOutliers: showOutliers ?? this.showOutliers,
      showAllPoints: showAllPoints ?? this.showAllPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      boxPlotMode: boxPlotMode ?? this.boxPlotMode,
      boxWidth: boxWidth ?? this.boxWidth,
      spacing: spacing ?? this.spacing,
      borderWidth: borderWidth ?? this.borderWidth,
      outlierSize: outlierSize ?? this.outlierSize,
    );
  }

  @override
  BoxPlotState withField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric) {
      return copyWith(columnName: columnName);
    }
    return this;
  }
}