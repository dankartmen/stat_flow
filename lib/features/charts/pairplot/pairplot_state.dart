import '../chart_state.dart';

/// {@template pairplot_state}
/// Состояние для Pair Plot (матрицы рассеяния) в системе плагинов.
/// 
/// Хранит настройки отображения матрицы рассеяния:
/// - [selectedColumns] — выбранные числовые колонки (null — все)
/// - [maxPoints] — максимальное количество точек на один scatter plot (0 — все точки)
/// - [pointSize] — размер точек
/// - [pointOpacity] — прозрачность точек
/// - [showCorrelation] — показывать коэффициент корреляции в углу ячейки
/// - [showHistogramOnDiagonal] — показывать гистограммы на диагонали
/// - [maxColumnsForTooltips] — максимальное количество колонок для включения тултипов
/// - [hueColumn] — имя колонки для окраски точек
/// - [useHue] — флаг, включена ли окраска
/// {@endtemplate}
class PairPlotState extends ChartState {
  /// Выбранные колонки для отображения. Если null — отображаются все числовые колонки.
  List<String>? selectedColumns;
  
  /// Максимальное количество точек на один scatter plot.
  /// Значение 0 интерпретируется как "все точки" (фактически ограничено 5000 в калькуляторе).
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

  /// Имя колонки, используемой для окраски точек (может быть числовой или категориальной).
  /// Используется только если [useHue] == true.
  String? hueColumn;
  
  /// Флаг, включена ли окраска по [hueColumn].
  bool useHue;
  
  /// {@macro pairplot_state}
  PairPlotState({
    this.selectedColumns,
    this.maxPoints = 500,
    this.pointSize = 3.0,
    this.pointOpacity = 0.6,
    this.showCorrelation = true,
    this.showHistogramOnDiagonal = true,
    this.maxColumnsForTooltips = 4,
    this.hueColumn,
    this.useHue = false,
  });

  /// Создаёт копию состояния с изменёнными полями.
  /// 
  /// Принимает именованные параметры только для тех полей, которые нужно изменить.
  /// Остальные копируются из текущего экземпляра.
  @override
  PairPlotState copyWith({
    List<String>? selectedColumns,
    int? maxPoints,
    double? pointSize,
    double? pointOpacity,
    bool? showCorrelation,
    bool? showHistogramOnDiagonal,
    int? maxColumnsForTooltips,
    String? hueColumn,
    bool? useHue,
  }) {
    return PairPlotState(
      selectedColumns: selectedColumns ?? this.selectedColumns,
      maxPoints: maxPoints ?? this.maxPoints,
      pointSize: pointSize ?? this.pointSize,
      pointOpacity: pointOpacity ?? this.pointOpacity,
      showCorrelation: showCorrelation ?? this.showCorrelation,
      showHistogramOnDiagonal: showHistogramOnDiagonal ?? this.showHistogramOnDiagonal,
      maxColumnsForTooltips: maxColumnsForTooltips ?? this.maxColumnsForTooltips,
      hueColumn: hueColumn ?? this.hueColumn,
      useHue: useHue ?? this.useHue,
    );
  }
}