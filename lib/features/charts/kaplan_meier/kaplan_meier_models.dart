import 'kaplan_meier_estimator.dart';

/// {@template kaplan_meier_chart_data}
/// Данные для графика Каплан-Мейера (одна или несколько кривых).
/// 
/// Содержит список кривых выживаемости и настройки отображения.
/// Используется в [KaplanMeierView] для построения графика.
/// {@endtemplate}
class KaplanMeierChartData {
  /// Список кривых выживаемости (каждая для своей группы).
  final List<KaplanMeierResult> curves;
  
  /// Показывать ли доверительные интервалы (95%).
  final bool showConfidenceIntervals;
  
  /// Показывать ли маркеры цензурированных наблюдений на кривых.
  final bool showCensoredMarks;

  /// {@macro kaplan_meier_chart_data}
  KaplanMeierChartData({
    required this.curves,
    this.showConfidenceIntervals = false,
    this.showCensoredMarks = true,
  });
}