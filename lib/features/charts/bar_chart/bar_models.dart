/// {@template bar_data}
/// Вспомогательный класс для хранения данных одной категории столбчатой диаграммы.
/// Содержит название категории и соответствующее значение (частоту, количество и т.п.).
/// {@endtemplate}
class BarData {
  /// Название категории (подпись на оси X).
  final String category;

  /// Значение (высота столбца).
  final double value;

  /// {@macro bar_data}
  BarData(this.category, this.value);
}

/// {@template bar_series_data}
/// Данные для одной серии (группы) столбчатой диаграммы.
/// Используется при группировке: каждая серия соответствует одной категории группировки.
/// {@endtemplate}
class BarSeriesData {
  /// Название группы (отображается в легенде).
  final String groupName;

  /// Список данных для этой группы (категории и их значения).
  final List<BarData> bars;

  /// {@macro bar_series_data}
  BarSeriesData(this.groupName, this.bars);
}