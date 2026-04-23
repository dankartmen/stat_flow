import 'package:stat_flow/core/dataset/dataset.dart';
import 'boxplot_models.dart';
import 'boxplot_state.dart';

/// {@template boxplot_data_calculator}
/// Калькулятор данных для ящика с усами (box plot).
/// 
/// Преобразует сырые данные из датасета в формат, пригодный для отображения.
/// Поддерживает:
/// - Без группировки — одна серия
/// - С группировкой по категориальной/текстовой колонке — несколько серий
/// - Сэмплирование при превышении лимита [maxPoints]
/// 
/// Возвращает список серий [BoxPlotSeriesData] и информацию о сэмплировании.
/// {@endtemplate}
class BoxPlotDataCalculator {
  /// Список серий данных для отображения.
  final List<BoxPlotSeriesData> seriesData;

  /// Флаг, указывающий, что данные были сэмплированы.
  final bool isSampled;

  /// Общее количество валидных значений до сэмплирования.
  final int totalCount;

  BoxPlotDataCalculator._(this.seriesData, this.isSampled, this.totalCount);

  /// Вычисляет данные на основе датасета и состояния.
  /// 
  /// Принимает:
  /// - [dataset] — исходный датасет
  /// - [state] — настройки отображения (выбранная колонка, группировка, maxPoints)
  /// 
  /// Возвращает:
  /// - [BoxPlotDataCalculator] с подготовленными данными
  static BoxPlotDataCalculator calculate({
    required Dataset dataset,
    required BoxPlotState state,
  }) {
    final columnName = state.columnName;
    if (columnName == null) {
      return BoxPlotDataCalculator._([], false, 0);
    }

    final column = dataset.column(columnName);
    if (column is! NumericColumn) {
      return BoxPlotDataCalculator._([], false, 0);
    }

    final allValues = column.data;

    // С группировкой
    if (state.groupByColumn != null) {
      return _processGrouped(dataset, state, column, allValues);
    }

    // Без группировки
    final validValues = allValues.whereType<double>().toList();
    final total = validValues.length;
    final sampled = validValues.length > state.maxPoints
        ? validValues.sample(state.maxPoints)
        : validValues;

    final series = BoxPlotSeriesData(columnName, sampled);
    return BoxPlotDataCalculator._(
      [series],
      sampled.length < total,
      total,
    );
  }

  /// Обрабатывает данные с группировкой.
  /// 
  /// Принимает:
  /// - [dataset] — датасет
  /// - [state] — состояние (содержит группирующую колонку)
  /// - [column] — числовая колонка
  /// - [allValues] — все значения колонки (с null)
  /// 
  /// Возвращает:
  /// - [BoxPlotDataCalculator] с несколькими сериями (по одной на группу)
  static BoxPlotDataCalculator _processGrouped(
    Dataset dataset,
    BoxPlotState state,
    NumericColumn column,
    List<double?> allValues,
  ) {
    final groupColName = state.groupByColumn!;
    final groupCol = dataset.column(groupColName);
    if (groupCol == null) {
      return BoxPlotDataCalculator._([], false, 0);
    }

    // Приводим группирующую колонку к списку строк
    List<String?> groupData;
    if (groupCol is CategoricalColumn) {
      groupData = groupCol.data;
    } else if (groupCol is TextColumn) {
      groupData = groupCol.data;
    } else {
      return BoxPlotDataCalculator._([], false, 0);
    }

    // Группируем числовые значения по категориям
    final groupsMap = <String, List<double>>{};
    int totalValid = 0;
    for (int i = 0; i < allValues.length; i++) {
      final val = allValues[i];
      final group = groupData[i];
      if (val != null && group != null) {
        groupsMap.putIfAbsent(group, () => []).add(val);
        totalValid++;
      }
    }

    final sortedGroups = groupsMap.keys.toList()..sort();
    final seriesList = <BoxPlotSeriesData>[];
    int totalSampled = 0;

    for (final group in sortedGroups) {
      final values = groupsMap[group]!;
      // Сэмплирование при необходимости
      final sampled = values.length > state.maxPoints
          ? values.sample(state.maxPoints)
          : values;
      totalSampled += sampled.length;
      seriesList.add(BoxPlotSeriesData(group, sampled));
    }

    final isSampled = totalSampled < totalValid;
    return BoxPlotDataCalculator._(seriesList, isSampled, totalValid);
  }
}