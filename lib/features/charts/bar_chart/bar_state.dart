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

  /// {@macro bar_state}
  BarState({
    this.columnName,
    this.showValues = false,
    this.barWidth = 0.7,
    this.alignment = BarAlignment.center,
  });

  @override
  void selectField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.categorical || 
        type == ColumnType.text || 
        type == ColumnType.numeric) {
      this.columnName = columnName;
    }
  }

  @override
  String toString() {
    return 'BarState(columnName: $columnName, showValues: $showValues, barWidth: $barWidth, alignment: $alignment)';
  }
}