import 'package:stat_flow/core/dataset/dataset.dart';
import 'kaplan_meier_estimator.dart';
import 'kaplan_meier_models.dart';
import 'kaplan_meier_state.dart';

/// {@template kaplan_meier_data_calculator}
/// Калькулятор данных для кривой выживаемости Каплан-Мейера.
/// 
/// Подготавливает данные из датасета для построения графика.
/// Поддерживает:
/// - Извлечение времени и события из числовой и категориальной колонок
/// - Группировку по категориальной колонке (построение нескольких кривых)
/// - Преобразование текстовых событий ("true"/"1"/"false"/"0") в бинарные значения
/// - Проверку типов и валидацию входных данных
/// 
/// Возвращает [KaplanMeierChartData] или сообщение об ошибке.
/// {@endtemplate}
class KaplanMeierDataCalculator {
  /// Рассчитанные данные для графика (null при ошибке).
  final KaplanMeierChartData? data;

  /// Сообщение об ошибке (если есть).
  final String? error;

  KaplanMeierDataCalculator._(this.data, this.error);

  /// Вычисляет данные на основе датасета и состояния.
  ///
  /// Принимает:
  /// - [dataset] — исходный датасет
  /// - [state] — настройки отображения (колонки, группировка)
  ///
  /// Возвращает:
  /// - экземпляр [KaplanMeierDataCalculator] с данными или ошибкой
  static KaplanMeierDataCalculator calculate({
    required Dataset dataset,
    required KaplanMeierState state,
  }) {
    if (state.timeColumn == null || state.eventColumn == null) {
      return KaplanMeierDataCalculator._(null, 'Выберите колонки времени и события');
    }

    final timeCol = dataset.column(state.timeColumn!);
    final eventCol = dataset.column(state.eventColumn!);

    if (timeCol is! NumericColumn) {
      return KaplanMeierDataCalculator._(null, 'Колонка времени должна быть числовой');
    }

    List<double> times;
    List<int> events;

    // Обработка колонки события из числовых данных (0/1)
    if (eventCol is NumericColumn) {
      times = [];
      events = [];
      for (int i = 0; i < timeCol.data.length; i++) {
        final t = timeCol.data[i];
        final e = eventCol.data[i];
        if (t != null && e != null) {
          times.add(t);
          events.add(e.toInt());
        }
      }
    } 
    // Обработка колонки события из категориальных или текстовых данных
    else if (eventCol is CategoricalColumn || eventCol is TextColumn) {
      times = [];
      events = [];
      for (int i = 0; i < timeCol.data.length; i++) {
        final t = timeCol.data[i];
        final e = eventCol!.data[i];
        if (t != null && e != null) {
          times.add(t);
          // Преобразуем строку в бинарное значение:
          // "1" или "true" (без учёта регистра) → 1 (событие)
          // остальные → 0 (цензурирование)
          events.add(e == '1' || e.toLowerCase() == 'true' ? 1 : 0);
        }
      }
    } else {
      return KaplanMeierDataCalculator._(null, 'Неверный тип колонки события');
    }

    if (times.isEmpty) {
      return KaplanMeierDataCalculator._(null, 'Нет данных');
    }

    // Группировка
    if (state.groupByColumn != null) {
      return _processGrouped(dataset, state, times, events);
    }

    // Одна кривая (без группировки)
    final result = KaplanMeierEstimator.estimate(
      times: times,
      events: events,
      groupName: 'Все пациенты',
    );

    final data = KaplanMeierChartData(
      curves: [result],
      showConfidenceIntervals: state.showConfidenceIntervals,
      showCensoredMarks: state.showCensoredMarks,
    );

    return KaplanMeierDataCalculator._(data, null);
  }

  /// Обрабатывает данные с группировкой по категориальной колонке.
  ///
  /// Принимает:
  /// - [dataset] — датасет
  /// - [state] — состояние (содержит groupByColumn)
  /// - [times] — список всех времён
  /// - [events] — список бинарных событий
  ///
  /// Возвращает:
  /// - [KaplanMeierDataCalculator] с несколькими кривыми (по одной на группу)
  static KaplanMeierDataCalculator _processGrouped(
    Dataset dataset,
    KaplanMeierState state,
    List<double> times,
    List<int> events,
  ) {
    final groupCol = dataset.column(state.groupByColumn!);
    if (groupCol == null) {
      return KaplanMeierDataCalculator._(null, 'Колонка группировки не найдена');
    }

    final Map<String, List<double>> groupTimes = {};
    final Map<String, List<int>> groupEvents = {};

    // Разносим данные по группам
    for (int i = 0; i < times.length; i++) {
      final group = groupCol[i]?.toString() ?? 'Unknown';
      groupTimes.putIfAbsent(group, () => []);
      groupEvents.putIfAbsent(group, () => []);
      groupTimes[group]!.add(times[i]);
      groupEvents[group]!.add(events[i]);
    }

    // Вычисляем кривую для каждой группы
    final curves = <KaplanMeierResult>[];
    for (final group in groupTimes.keys.toList()..sort()) {
      if (groupTimes[group]!.isNotEmpty) {
        final result = KaplanMeierEstimator.estimate(
          times: groupTimes[group]!,
          events: groupEvents[group]!,
          groupName: group,
        );
        curves.add(result);
      }
    }

    if (curves.length < 2) {
      return KaplanMeierDataCalculator._(null, 'Слишком мало групп для сравнения');
    }

    final data = KaplanMeierChartData(
      curves: curves,
      showConfidenceIntervals: state.showConfidenceIntervals,
      showCensoredMarks: state.showCensoredMarks,
    );

    return KaplanMeierDataCalculator._(data, null);
  }
}