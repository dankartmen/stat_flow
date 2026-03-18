import '../chart_state.dart';

/// {@template line_state}
/// Состояние линейного графика для системы плагинов
/// 
/// Хранит настройки отображения линейного графика:
/// - [columnName] — имя выбранной числовой колонки для оси Y
/// - [showMarkers] — показывать маркеры на точках
/// - [showGridLines] — показывать сетку
/// {@endtemplate}
class LineState extends ChartState {
  /// Имя выбранной числовой колонки для оси Y
  String? columnName;
  
  /// Показывать маркеры на точках
  bool showMarkers;
  
  /// Показывать сетку
  bool showGridLines;

  /// {@macro line_state}
  LineState({
    this.columnName,
    this.showMarkers = true,
    this.showGridLines = true,
  });

  @override
  void selectField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric) {
      this.columnName = columnName;
    }
  }
}