import '../chart_state.dart';

/// Тип выравнивания столбцов
enum BarAlignment {
  far,
  near,
  center,
}

/// {@template bar_state}
/// Состояние столбчатой диаграммы для системы плагинов
/// 
/// Хранит настройки отображения столбчатой диаграммы:
/// - [columnName] — имя выбранной числовой колонки
/// - [showValues] — показывать значения на столбцах
/// - [barWidth] — ширина столбцов (0.1-1.0)
/// - [alignment] — выравнивание столбцов
/// {@endtemplate}
class BarState extends ChartState {
  /// Имя выбранной числовой колонки
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
}