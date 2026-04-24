/// {@template histogram_series_data}
/// Данные для одной серии гистограммы.
/// 
/// Содержит название группы (отображается в легенде) и список числовых значений.
/// Для гистограммы с разбиением по категориям каждая серия соответствует
/// одной категории и содержит значения только из этой категории.
/// {@endtemplate}
class HistogramSeriesData {
  /// Название группы (отображается в легенде).
  final String groupName;

  /// Список числовых значений для построения гистограммы.
  final List<double> values;

  /// {@macro histogram_series_data}
  HistogramSeriesData(this.groupName, this.values);
}