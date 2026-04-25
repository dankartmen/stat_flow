import '../chart_state.dart';

/// {@template kaplan_meier_state}
/// Состояние для кривой выживаемости Каплан-Мейера в системе плагинов.
/// 
/// Хранит настройки отображения кривой выживаемости:
/// - [timeColumn] — числовая колонка с временем наблюдения
/// - [eventColumn] — категориальная/текстовая колонка с бинарным событием
/// - [groupByColumn] — колонка для группировки (сравнение нескольких кривых)
/// - [showConfidenceIntervals] — показывать доверительные интервалы
/// - [showCensoredMarks] — показывать маркеры цензурированных наблюдений
/// - [lineWidth] — толщина линии на графике
/// {@endtemplate}
class KaplanMeierState extends ChartState {
  /// Название числовой колонки, содержащей время наблюдения (например, дни до события/цензуры).
  String? timeColumn;
  
  /// Название колонки, содержащей бинарное событие (1 — событие произошло, 0 — цензурировано).
  /// Поддерживаются числовые (0/1) и текстовые ("true"/"false", "1"/"0") колонки.
  String? eventColumn;
  
  /// Название категориальной колонки для группировки (если null — строится одна кривая).
  String? groupByColumn;
  
  /// Показывать ли 95% доверительные интервалы для каждой кривой.
  bool showConfidenceIntervals;
  
  /// Показывать ли маркеры на кривых в местах цензурирования наблюдений.
  bool showCensoredMarks;
  
  /// Толщина линии кривой выживаемости в пикселях.
  double lineWidth;

  /// {@macro kaplan_meier_state}
  KaplanMeierState({
    this.timeColumn,
    this.eventColumn,
    this.groupByColumn,
    this.showConfidenceIntervals = false,
    this.showCensoredMarks = true,
    this.lineWidth = 2.5,
  });

  /// Создаёт копию состояния с изменёнными полями.
  @override
  KaplanMeierState copyWith({
    String? timeColumn,
    String? eventColumn,
    String? groupByColumn,
    bool? showConfidenceIntervals,
    bool? showCensoredMarks,
    double? lineWidth,
  }) {
    return KaplanMeierState(
      timeColumn: timeColumn ?? this.timeColumn,
      eventColumn: eventColumn ?? this.eventColumn,
      groupByColumn: groupByColumn ?? this.groupByColumn,
      showConfidenceIntervals: showConfidenceIntervals ?? this.showConfidenceIntervals,
      showCensoredMarks: showCensoredMarks ?? this.showCensoredMarks,
      lineWidth: lineWidth ?? this.lineWidth,
    );
  }

  /// Обновляет состояние при выборе колонки из панели управления.
  ///
  /// Принимает:
  /// - [columnName] — имя выбранной колонки
  /// - [type] — тип колонки (числовая, категориальная, текстовая)
  ///
  /// Возвращает:
  /// - новое состояние с обновлённой соответствующей колонкой.
  @override
  KaplanMeierState withField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric) {
      return copyWith(timeColumn: columnName);
    }
    if (type == ColumnType.categorical || type == ColumnType.text) {
      return copyWith(eventColumn: columnName);
    }
    return this;
  }
}