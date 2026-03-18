import '../chart_state.dart';

/// {@template scatter_state}
/// Состояние диаграммы рассеяния для системы плагинов
/// 
/// Хранит настройки отображения scatter plot:
/// - [firstColumnName] — имя первой выбранной числовой колонки (ось X)
/// - [secondColumnName] — имя второй выбранной числовой колонки (ось Y)
/// 
/// Наследуется от [ChartState] для интеграции с системой плагинов.
/// {@endtemplate}
class ScatterState extends ChartState {
  /// Имя первой числовой колонки (ось X)
  String? firstColumnName;
  
  /// Имя второй числовой колонки (ось Y)
  String? secondColumnName;

  /// {@macro scatter_state}
  ScatterState({
    this.firstColumnName,
    this.secondColumnName,
  });

  @override
  void selectField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric) {
      if (firstColumnName == null) {
        firstColumnName = columnName;
      } else {
        secondColumnName ??= columnName;
      }
    }
  }
}