import '../chart_state.dart';

/// Тип выравнивания подписей значений на столбцах.
enum BarAlignment {
  /// Выравнивание по дальнему краю (относительно столбца).
  far,
  
  /// Выравнивание по ближнему краю.
  near,
  
  /// Выравнивание по центру.
  center,
}

/// {@template bar_state}
/// Состояние столбчатой диаграммы для системы плагинов.
/// 
/// Хранит настройки отображения столбчатой диаграммы:
/// - [columnName] — имя выбранной колонки (может быть категориальной, текстовой или числовой)
/// - [groupByColumn] — колонка для группировки (строятся несколько серий)
/// - [stacked] — режим составных столбцов (stacked)
/// - [showValues] — показывать значения на столбцах
/// - [barWidth] — ширина столбцов (0.1-1.0)
/// - [alignment] — выравнивание подписей значений
/// - [binCount] — количество интервалов для числовых данных (гистограмма)
/// - [maxCategories] — максимальное количество категорий для отображения
/// - [showTrack] — показывать трек (фон) для столбцов
/// - [borderRadius] — радиус скругления углов столбцов
/// - [borderWidth] — толщина границы столбцов
/// - [spacing] — расстояние между столбцами (в относительных единицах)
/// - [sortDescending] — сортировать категории по убыванию частоты
/// {@endtemplate}
class BarState extends ChartState {
  /// Имя выбранной колонки.
  String? columnName;
  
  /// Колонка для группировки (категориальная или текстовая).
  String? groupByColumn;

  /// Флаг stacked-режима (составные столбцы).
  bool stacked;

  /// Показывать значения на столбцах.
  bool showValues;
  
  /// Ширина столбцов в относительных единицах (0.1-1.0).
  double barWidth;
  
  /// Выравнивание подписей значений.
  BarAlignment alignment;

  /// Количество интервалов для числовых данных (гистограмма).
  int binCount;

  /// Максимальное количество категорий для отображения (для категориальных данных).                   
  int maxCategories;

  /// Показывать трек (фон для столбцов).
  bool showTrack;

  /// Радиус скругления углов столбцов (в пикселях).
  double borderRadius;

  /// Толщина границы столбцов (в пикселях).
  double borderWidth;

  /// Расстояние между столбцами (относительное, 0…1).
  double spacing;

  /// Сортировать категории по убыванию частоты (для категориальных данных).
  bool sortDescending;
  
  /// {@macro bar_state}
  BarState({
    this.columnName,
    this.groupByColumn,
    this.stacked = false,
    this.showValues = false,
    this.barWidth = 0.7,
    this.alignment = BarAlignment.center,
    this.binCount = 12,
    this.maxCategories = 20,
    this.showTrack = false,
    this.borderRadius = 6.0,
    this.borderWidth = 1.5,
    this.spacing = 0.2,
    this.sortDescending = true,
  });
  
  /// Создаёт копию состояния с изменёнными полями.
  @override
  BarState copyWith({
    String? columnName,
    String? groupByColumn,
    bool? stacked,
    bool? showValues,
    double? barWidth,
    BarAlignment? alignment,
    int? binCount,
    int? maxCategories,
    bool? showTrack,
    double? borderRadius,
    double? borderWidth,
    double? spacing,
    bool? sortDescending,
  }) {
    return BarState(
      columnName: columnName ?? this.columnName,
      groupByColumn: groupByColumn ?? this.groupByColumn,
      stacked: stacked ?? this.stacked,
      showValues: showValues ?? this.showValues,
      barWidth: barWidth ?? this.barWidth,
      alignment: alignment ?? this.alignment,
      binCount: binCount ?? this.binCount,
      maxCategories: maxCategories ?? this.maxCategories,
      showTrack: showTrack ?? this.showTrack,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      spacing: spacing ?? this.spacing,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Сбрасывает группировку, оставляя остальные настройки неизменными.
  /// 
  /// Полезно при переключении между группированным и негруппированным режимом.
  /// 
  /// Возвращает:
  /// - новый экземпляр [BarState] с [groupByColumn] = null.
  BarState resetGroupBy() {
    return BarState(
      columnName: columnName,
      groupByColumn: null,
      stacked: stacked,
      showValues: showValues,
      barWidth: barWidth,
      alignment: alignment,
      binCount: binCount,
      maxCategories: maxCategories,
      showTrack: showTrack,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      spacing: spacing,
      sortDescending: sortDescending,
    );
  }
  
  /// Обновляет состояние при выборе колонки из панели управления.
  /// 
  /// Принимает:
  /// - [columnName] — имя выбранной колонки
  /// - [type] — тип колонки (категориальная, текстовая, числовая)
  /// 
  /// Возвращает:
  /// - новое состояние с обновлённой колонкой, если тип поддерживается,
  ///   иначе текущее состояние без изменений.
  @override
  BarState withField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.categorical || 
        type == ColumnType.text || 
        type == ColumnType.numeric) {
      return copyWith(columnName: columnName);
    }
    return this;
  }

  @override
  String toString() {
    return 'BarState(columnName: $columnName, groupByColumn: $groupByColumn, showValues: $showValues, barWidth: $barWidth, alignment: $alignment)';
  }
}