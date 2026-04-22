import 'package:stat_flow/core/dataset/dataset.dart';
import 'bar_models.dart';
import 'bar_state.dart';
import 'bar_view.dart';

/// {@template bar_data_calculator}
/// Калькулятор данных для столбчатой диаграммы.
/// 
/// Преобразует сырые данные из [Dataset] в формат, пригодный для отображения
/// в [BarView]. Поддерживает:
/// - Числовые колонки → гистограмма с группировкой в интервалы
/// - Категориальные/текстовые колонки → подсчёт частот
/// - Группировку по другой колонке → несколько серий
/// - Сэмплирование при большом количестве точек
/// {@endtemplate}
class BarDataCalculator {
  /// Результат расчёта: список серий данных.
  final List<BarSeriesData> seriesData;

  /// Флаг, указывающий, что данные были сэмплированы.
  final bool isSampled;

  BarDataCalculator._(this.seriesData, this.isSampled);

  /// Вычисляет данные на основе датасета и состояния.
  ///
  /// Принимает:
  /// - [dataset] — исходный датасет
  /// - [state] — настройки отображения (выбранная колонка, группировка, количество интервалов и т.д.)
  ///
  /// Возвращает:
  /// - экземпляр [BarDataCalculator] с подготовленными данными
  static BarDataCalculator calculate({
    required Dataset dataset,
    required BarState state,
  }) {
    if (state.columnName == null) {
      return BarDataCalculator._([], false);
    }

    final column = dataset.column(state.columnName!);
    if (column == null) {
      return BarDataCalculator._([], false);
    }

    // Группировка
    if (state.groupByColumn != null) {
      return _processGrouped(dataset, state, column);
    }

    // Без группировки
    if (column is NumericColumn) {
      return _processNumeric(state, column);
    } else if (column is CategoricalColumn || column is TextColumn) {
      return _processCategorical(state, column);
    } else {
      return BarDataCalculator._([], false);
    }
  }

  /// Обрабатывает числовую колонку — строит гистограмму с заданным количеством интервалов.
  ///
  /// Принимает:
  /// - [state] — состояние (содержит binCount)
  /// - [column] — числовая колонка
  ///
  /// Возвращает:
  /// - [BarDataCalculator] с одной серией (гистограмма частот)
  static BarDataCalculator _processNumeric(BarState state, NumericColumn column) {
    final allValues = column.data.whereType<double>().toList();
    if (allValues.isEmpty) return BarDataCalculator._([], false);

    // Сэмплирование при превышении порога (5000 точек)
    final values = allValues.length > 5000
        ? allValues.sample(5000)
        : allValues;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final binCount = state.binCount;
    final binWidth = (max - min) / binCount;

    // Построение интервалов
    final bins = List.generate(binCount, (i) {
      final binMin = min + i * binWidth;
      final binMax = binMin + binWidth;
      final count = values.where((v) {
        if (i == binCount - 1) {
          // последний интервал включает правую границу
          return v >= binMin && v <= binMax;
        } else {
          return v >= binMin && v < binMax;
        }
      }).length;
      return BarData('${binMin.toStringAsFixed(2)}-${binMax.toStringAsFixed(2)}', count.toDouble());
    });

    final series = BarSeriesData('Частота', bins);
    return BarDataCalculator._([series], values.length != allValues.length);
  }

  /// Обрабатывает категориальную или текстовую колонку — считает частоты.
  ///
  /// Принимает:
  /// - [state] — состояние (содержит maxCategories, sortDescending)
  /// - [column] — колонка с категориями
  ///
  /// Возвращает:
  /// - [BarDataCalculator] с одной серией (частоты категорий)
  static BarDataCalculator _processCategorical(BarState state, DataColumn column) {
    final valueCounts = <String, int>{};
    final data = column.data;
    for (final value in data) {
      if (value != null && value is String) {
        valueCounts[value] = (valueCounts[value] ?? 0) + 1;
      }
    }
    final entries = valueCounts.entries.toList();
    // Сортировка
    if (state.sortDescending) {
      entries.sort((a, b) => b.value.compareTo(a.value));
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    final maxCat = state.maxCategories;
    final topEntries = entries.take(maxCat).toList();
    final bars = topEntries.map((e) => BarData(e.key, e.value.toDouble())).toList();

    final series = BarSeriesData('Частота', bars);
    return BarDataCalculator._([series], entries.length > maxCat);
  }

  /// Обрабатывает данные с группировкой — строит несколько серий (по одной на категорию группировки).
  ///
  /// Принимает:
  /// - [dataset] — датасет
  /// - [state] — состояние (содержит группирующую колонку, maxCategories, sortDescending)
  /// - [mainColumn] — основная колонка (категориальная или текстовая)
  ///
  /// Возвращает:
  /// - [BarDataCalculator] с несколькими сериями (stacked или grouped)
  static BarDataCalculator _processGrouped(Dataset dataset, BarState state, DataColumn mainColumn) {
    final groupByColName = state.groupByColumn!;
    final groupByCol = dataset.column(groupByColName);
    if (groupByCol == null) return BarDataCalculator._([], false);

    // Приводим основную колонку к категориальному типу
    CategoricalColumn catMain;
    if (mainColumn is CategoricalColumn) {
      catMain = mainColumn;
    } else if (mainColumn is TextColumn) {
      catMain = CategoricalColumn(mainColumn.name, mainColumn.data);
    } else {
      return BarDataCalculator._([], false);
    }

    // Приводим группирующую колонку к категориальному типу
    CategoricalColumn catGroup;
    if (groupByCol is CategoricalColumn) {
      catGroup = groupByCol;
    } else if (groupByCol is TextColumn) {
      catGroup = CategoricalColumn(groupByCol.name, groupByCol.data);
    } else {
      return BarDataCalculator._([], false);
    }

    // Строим перекрёстную таблицу: основная категория -> (группа -> частота)
    final crossTable = <String, Map<String, int>>{};
    final allGroups = <String>{};

    for (int i = 0; i < catMain.data.length; i++) {
      final mainVal = catMain.data[i];
      final groupVal = catGroup.data[i];
      if (mainVal == null || groupVal == null) continue;
      allGroups.add(groupVal);
      crossTable.putIfAbsent(mainVal, () => {});
      crossTable[mainVal]![groupVal] = (crossTable[mainVal]![groupVal] ?? 0) + 1;
    }

    final groups = allGroups.toList()..sort();
    var entries = crossTable.entries.toList();

    // Сортировка основных категорий
    if (state.sortDescending) {
      entries.sort((a, b) {
        final sumA = a.value.values.fold(0, (s, v) => s + v);
        final sumB = b.value.values.fold(0, (s, v) => s + v);
        return sumB.compareTo(sumA);
      });
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    final limitedEntries = entries.take(state.maxCategories).toList();

    // Формируем серии: каждая группа → список значений по основным категориям
    final seriesDataList = <BarSeriesData>[];
    for (final group in groups) {
      final bars = limitedEntries.map((entry) {
        final count = entry.value[group] ?? 0;
        return BarData(entry.key, count.toDouble());
      }).toList();
      seriesDataList.add(BarSeriesData(group, bars));
    }

    return BarDataCalculator._(seriesDataList, entries.length > state.maxCategories);
  }
}