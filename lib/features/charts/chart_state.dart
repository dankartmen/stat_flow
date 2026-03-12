/// {@template chart_state}
/// Базовый абстрактный класс для состояний графиков
/// 
/// Используется в системе плагинов для хранения специфичного
/// для каждого типа графика состояния (настройки отображения,
/// выбранные параметры и т.д.).
/// {@endtemplate}
abstract class ChartState {
  /// {@macro chart_state}
  const ChartState();
}

/// {@template empty_chart_state}
/// Пустое состояние графика (заглушка)
/// 
/// Используется для графиков, которые не требуют сохранения состояния,
/// или как состояние по умолчанию.
/// {@endtemplate}
class EmptyChartState extends ChartState {
  /// {@macro empty_chart_state}
  const EmptyChartState();
}