import '../chart_state.dart';

/// {@template boxplot_state}
/// Состояние ящика с усами (box plot) для системы плагинов
/// 
/// Хранит настройки отображения ящика с усами:
/// - [columnName] — имя выбранной числовой колонки для анализа
/// 
/// Наследуется от [ChartState] для интеграции с системой плагинов.
/// {@endtemplate}
class BoxPlotState extends ChartState {
  /// Имя выбранной числовой колонки для отображения
  String? columnName;

  /// {@macro boxplot_state}
  BoxPlotState({
    this.columnName,
  });
}