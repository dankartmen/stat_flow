import '../chart_state.dart';

/// Тип выравнивания столбцов
enum BarAlignment {
  /// Выравнивание по дальнему краю
  far,
  
  /// Выравнивание по ближнему краю
  near,
  
  /// Выравнивание по центру
  center,
}

/// {@template bar_state}
/// Состояние столбчатой диаграммы для системы плагинов
/// 
/// Хранит настройки отображения столбчатой диаграммы:
/// - [columnName] — имя выбранной колонки (может быть категориальной, текстовой или числовой)
/// - [showValues] — показывать значения на столбцах
/// - [barWidth] — ширина столбцов (0.1-1.0)
/// - [alignment] — выравнивание столбцов
/// {@endtemplate}
class BarState extends ChartState {
  /// Имя выбранной колонки
  String? columnName;
  
  /// Показывать значения на столбцах
  bool showValues;
  
  /// Ширина столбцов (0.1-1.0)
  double barWidth;
  
  /// Выравнивание столбцов
  BarAlignment alignment;

  /// Количество корзин для числовых данных
  int binCount;

  /// Максимальное количество категорий для отображения (для категориальных данных)                   
  int maxCategories;

  /// Показывать трек (фон для столбцов)
  bool showTrack;

  /// Радиус скругления углов столбцов
  double borderRadius;

  /// Толщина границы столбцов
  double borderWidth;

  /// Расстояние между столбцами (для категориальных данных)
  double spacing;

  /// Сортировать категории по убыванию (для категориальных данных)
  bool sortDescending;
  
  /// {@macro bar_state}
  BarState({
    this.columnName,
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

  @override
  BarState copyWith({
    String? columnName,
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
    return 'BarState(columnName: $columnName, showValues: $showValues, barWidth: $barWidth, alignment: $alignment)';
  }
}