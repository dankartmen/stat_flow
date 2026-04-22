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
  /// Имя выбранной числовой колонки для отображения.
  String? columnName;

  /// Колонка для группировки (категориальная или текстовая).
  /// Если указана, строятся несколько ящиков — по одному на каждую категорию.
  String? groupByColumn;

  /// Показывать ли на графике среднее значение (маркером).
  bool showMean;

  /// Показывать ли выбросы (outliers) — точки за пределами усов.
  bool showOutliers;

  /// Показывать все точки (с джиттером) поверх ящика.
  bool showAllPoints;

  /// Максимальное количество точек для расчёта и отображения.
  /// При превышении выполняется сэмплирование.
  int maxPoints;

  /// Режим расчёта box plot: обычный (нормальный), исключительный или включающий.
  BoxPlotMode boxPlotMode;

  /// Ширина ящика в относительных единицах (0.1–1.0).
  double boxWidth;

  /// Отступ между ящиками (для будущей поддержки нескольких серий).
  double spacing;

  /// Толщина границы ящика и усов в пикселях.
  double borderWidth;

  /// Размер маркеров выбросов в пикселях.
  double outlierSize;

  /// {@macro boxplot_state}
  BoxPlotState({
    this.columnName,
    this.groupByColumn,
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

  /// Создаёт копию состояния с изменёнными полями.
  @override
  BoxPlotState copyWith({
    String? columnName,
    String? groupByColumn,
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
      groupByColumn: groupByColumn ?? this.groupByColumn,
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

  /// Обновляет состояние при выборе колонки из панели управления.
  /// 
  /// Принимает:
  /// - [columnName] — имя выбранной колонки
  /// - [type] — тип колонки (если известен)
  /// 
  /// Возвращает:
  /// - новое состояние с обновлённой колонкой, если тип числовой
  @override
  BoxPlotState withField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric) {
      return copyWith(columnName: columnName);
    }
    return this;
  }
}