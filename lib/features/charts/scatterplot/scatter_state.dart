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
  ScatterState copyWith({String? firstColumnName, String? secondColumnName}) {
    return ScatterState(
      firstColumnName: firstColumnName ?? this.firstColumnName,
      secondColumnName: secondColumnName ?? this.secondColumnName,
    );
  }

  @override
  ScatterState withField(String columnName, {ColumnType? type}) {
    return this;
  }
}