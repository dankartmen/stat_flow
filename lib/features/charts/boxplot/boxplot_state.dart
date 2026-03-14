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

  /// Показывать ли на графике среднее значение
  bool showMean;

  /// Показывать ли выбросы (outliers)
  bool showOutliers;

  /// Максимальное количество точек, используемых для расчета статистики и отображения
  /// (для ускорения работы на больших датасетах).
  int maxPoints;

  /// {@macro boxplot_state}
  BoxPlotState({
    this.columnName,
    this.showMean = true,
    this.showOutliers = true,
    this.maxPoints = 5000,
  });
}