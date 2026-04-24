import 'package:stat_flow/core/dataset/dataset.dart';
import 'histogram_models.dart';
import 'histogram_state.dart';

/// {@template histogram_data_calculator}
/// Калькулятор данных для гистограммы.
/// 
/// Преобразует сырые данные из датасета в формат, пригодный для отображения.
/// Поддерживает:
/// - Без разбиения — одна серия
/// - С разбиением по категориальной/текстовой колонке — несколько серий
/// 
/// Примечание: сэмплирование для гистограммы в текущей реализации не выполняется,
/// так как гистограмма агрегирует данные в бины и хорошо работает с большими объёмами.
/// {@endtemplate}
class HistogramDataCalculator {
  /// Список серий данных для отображения.
  final List<HistogramSeriesData> seriesData;

  /// Флаг, указывающий, что данные были сэмплированы.
  /// В текущей реализации всегда false.
  final bool isSampled;

  /// Общее количество валидных значений.
  final int totalCount;

  HistogramDataCalculator._(this.seriesData, this.isSampled, this.totalCount);

  /// Вычисляет данные на основе датасета и состояния.
  /// 
  /// Принимает:
  /// - [dataset] — исходный датасет
  /// - [state] — настройки отображения (выбранная колонка, разбиение)
  /// 
  /// Возвращает:
  /// - [HistogramDataCalculator] с подготовленными данными
  static HistogramDataCalculator calculate({
    required Dataset dataset,
    required HistogramState state,
  }) {
    final columnName = state.columnName;
    if (columnName == null) {
      return HistogramDataCalculator._([], false, 0);
    }

    final column = dataset.column(columnName);
    if (column is! NumericColumn) {
      return HistogramDataCalculator._([], false, 0);
    }

    final allValues = column.data;

    // Если указана колонка для разбиения — строим несколько серий
    if (state.splitByColumn != null) {
      return _processSplit(dataset, state, column, allValues);
    }

    // Обычная гистограмма (одна серия)
    final validValues = allValues.whereType<double>().toList();
    if (validValues.isEmpty) {
      return HistogramDataCalculator._([], false, 0);
    }
    final series = HistogramSeriesData(columnName, validValues);
    return HistogramDataCalculator._([series], false, validValues.length);
  }

  /// Обрабатывает данные с разбиением по категориальной колонке.
  /// 
  /// Принимает:
  /// - [dataset] — датасет
  /// - [state] — состояние (содержит splitByColumn)
  /// - [numCol] — числовая колонка
  /// - [allValues] — все значения колонки (с null)
  /// 
  /// Возвращает:
  /// - [HistogramDataCalculator] с несколькими сериями (по одной на категорию)
  static HistogramDataCalculator _processSplit(
    Dataset dataset,
    HistogramState state,
    NumericColumn numCol,
    List<double?> allValues,
  ) {
    final splitColName = state.splitByColumn!;
    final splitCol = dataset.column(splitColName);
    if (splitCol == null) {
      return HistogramDataCalculator._([], false, 0);
    }

    // Приводим разбивающую колонку к списку строк
    List<String?> splitData;
    if (splitCol is CategoricalColumn) {
      splitData = splitCol.data;
    } else if (splitCol is TextColumn) {
      splitData = splitCol.data;
    } else {
      return HistogramDataCalculator._([], false, 0);
    }

    // Группируем числовые значения по категориям
    final groupsMap = <String, List<double>>{};
    int total = 0;
    for (int i = 0; i < allValues.length; i++) {
      final val = allValues[i];
      final group = splitData[i];
      // Учитываем только пары с не-null значениями
      if (val != null && group != null) {
        groupsMap.putIfAbsent(group, () => []).add(val);
        total++;
      }
    }

    // Сортируем группы для стабильного порядка отображения
    final sortedGroups = groupsMap.keys.toList()..sort();
    final seriesList = sortedGroups
        .map((group) => HistogramSeriesData(group, groupsMap[group]!))
        .toList();

    return HistogramDataCalculator._(seriesList, false, total);
  }
}