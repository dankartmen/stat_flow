/// {@template chart_state}
/// Базовый абстрактный класс для состояний графиков
/// 
/// Используется в системе плагинов для хранения специфичного
/// для каждого типа графика состояния (настройки отображения,
/// выбранные параметры и т.д.).
/// {@endtemplate}
abstract class ChartState {
  
  /// Возвращает новое состояние с выбранным полем (используется при создании графика из панели полей)
  ChartState withField(String columnName, {ColumnType? type}) => this;

  /// Создаёт копию состояния с изменёнными параметрами
  ChartState copyWith();

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

  @override
  ChartState copyWith() => this;
}

enum ColumnType { numeric, text, dateTime, categorical }