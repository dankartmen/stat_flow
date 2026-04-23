/// {@template boxplot_series_data}
/// Данные для одной серии (группы) ящика с усами.
/// Используется для передачи в [BoxPlotView] после обработки группировки.
/// {@endtemplate}
class BoxPlotSeriesData {
  /// Название группы (категория или имя колонки).
  /// Отображается на оси X и в легенде.
  final String groupName;

  /// Список числовых значений в этой группе.
  /// Может быть сэмплирован для производительности.
  final List<double> values;

  /// {@macro boxplot_series_data}
  BoxPlotSeriesData(this.groupName, this.values);

  @override
  String toString() {
    return 'Группа: $groupName \tЗначения: $values';
  }
}