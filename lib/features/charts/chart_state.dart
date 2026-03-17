/// {@template chart_state}
/// Базовый абстрактный класс для состояний графиков
/// 
/// Используется в системе плагинов для хранения специфичного
/// для каждого типа графика состояния (настройки отображения,
/// выбранные параметры и т.д.).
/// {@endtemplate}
abstract class ChartState {
  
  /// Вызывается при создании графика через правую панель,
  /// чтобы передать выбранное поле.
  /// По умолчанию ничего не делает, переопределяется в конкретных состояниях.
  void selectField(String columnName, {ColumnType? type}) {}

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

enum ColumnType { numeric, text, dateTime, categorical }