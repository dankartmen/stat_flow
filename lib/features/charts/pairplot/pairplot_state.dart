import '../chart_state.dart';

/// {@template pairplot_state}
/// Состояние для Pair Plot (матрицы рассеяния) в системе плагинов.
/// 
/// Хранит настройки отображения матрицы рассеяния:
/// - [selectedColumns] — выбранные числовые колонки (null — все)
/// - [maxPoints] — максимальное количество точек на один scatter plot
/// - [pointSize] — размер точек
/// - [pointOpacity] — прозрачность точек
/// - [showCorrelation] — показывать коэффициент корреляции в углу ячейки
/// - [showHistogramOnDiagonal] — показывать гистограммы на диагонали
/// - [maxColumnsForTooltips] — максимальное количество колонок для включения тултипов
/// {@endtemplate}
class PairPlotState extends ChartState {
  /// Выбранные колонки для отображения. Если null — отображаются все числовые колонки.
  List<String>? selectedColumns;
  
  /// Максимальное количество точек на один scatter plot.
  int maxPoints;
  
  /// Размер точек (в пикселях).
  double pointSize;
  
  /// Прозрачность точек (0.0 — полностью прозрачные, 1.0 — непрозрачные).
  double pointOpacity;
  
  /// Показывать коэффициент корреляции Пирсона в углу каждой недиагональной ячейки.
  bool showCorrelation;
  
  /// Показывать гистограммы на диагональных ячейках вместо названий колонок.
  bool showHistogramOnDiagonal;
  
  /// Максимальное количество колонок, при котором включаются тултипы.
  /// При большем количестве колонок тултипы отключаются для производительности.
  int maxColumnsForTooltips;

  /// {@macro pairplot_state}
  PairPlotState({
    this.selectedColumns,
    this.maxPoints = 500,
    this.pointSize = 3.0,
    this.pointOpacity = 0.6,
    this.showCorrelation = true,
    this.showHistogramOnDiagonal = true,
    this.maxColumnsForTooltips = 4,
  });

  /// Создаёт копию состояния с изменёнными полями.
  @override
  PairPlotState copyWith({
    List<String>? selectedColumns,
    int? maxPoints,
    double? pointSize,
    double? pointOpacity,
    bool? showCorrelation,
    bool? showHistogramOnDiagonal,
    int? maxColumnsForTooltips,
  }) {
    return PairPlotState(
      selectedColumns: selectedColumns ?? this.selectedColumns,
      maxPoints: maxPoints ?? this.maxPoints,
      pointSize: pointSize ?? this.pointSize,
      pointOpacity: pointOpacity ?? this.pointOpacity,
      showCorrelation: showCorrelation ?? this.showCorrelation,
      showHistogramOnDiagonal: showHistogramOnDiagonal ?? this.showHistogramOnDiagonal,
      maxColumnsForTooltips: maxColumnsForTooltips ?? this.maxColumnsForTooltips,
    );
  }
}