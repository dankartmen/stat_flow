import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import '../../chart_state.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_state.dart';

/// {@template heatmap_data_builder}
/// Строитель данных для тепловой карты на основе датасета и состояния графика
///
/// Отвечает за:
/// - Определение типа входных колонок (числовые, категориальные, текстовые)
/// - Построение корреляционной матрицы для всех числовых полей
/// - Построение таблицы сопряжённости для двух категориальных колонок
/// - Построение агрегированных данных для пары "категориальная + числовая"
/// - Обработку случаев, когда одна из колонок не указана (режим корреляции)
///
/// Возвращает готовый объект [HeatmapData], который может быть отрисован.
/// {@endtemplate}
class HeatmapDataBuilder {
  /// Датасет, содержащий данные для построения тепловой карты
  final Dataset dataset;

  /// Текущее состояние графика (выбранные колонки, тип агрегации)
  final HeatmapState state;

  /// Максимальное количество уникальных категорий для отображения
  static const int maxUniqueCategories = 50;
  
  /// {@macro heatmap_data_builder}
  HeatmapDataBuilder(this.dataset, this.state);

  /// Строит [HeatmapData] на основе текущего состояния и датасета
  ///
  /// Логика построения:
  /// - Если ни одна из колонок не выбрана (state.xColumn == null && state.yColumn == null):
  ///   возвращается корреляционная матрица всех числовых полей датасета.
  /// - Если выбраны обе колонки, анализируются их типы:
  ///   - Обе числовые: не поддерживается (возвращается пустая матрица).
  ///   - Обе категориальные (текст или категория): строится таблица сопряжённости (counts).
  ///   - Одна категориальная, другая числовая: строится агрегация (сумма, среднее и т.д.)
  ///   по категориям.
  /// - Если комбинация типов не поддерживается, выбрасывается исключение.
  ///
  /// Возвращает:
  /// - [HeatmapData] — данные для отображения тепловой карты.
  ///
  /// Выбрасывает:
  /// - [Exception] — при неподдерживаемой комбинации типов колонок.
  HeatmapData build() {
    // Режим корреляции всех числовых полей
    if (state.xColumn == null && state.yColumn == null) {
      final matrix = dataset.corr();
      return HeatmapData.fromCorrelation(matrix);
    }

    // Проверяем, что колонки существуют
    final xCol = dataset.column(state.xColumn!);
    final yCol = dataset.column(state.yColumn!);
    if (xCol == null || yCol == null) {
      log('Колонки не найдены');
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    final xType = _getColumnType(xCol);
    final yType = _getColumnType(yCol);

    // Случай: обе числовые — не поддерживаем (возвращаем пустую матрицу)
    if (xType == ColumnType.numeric && yType == ColumnType.numeric) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    // Случай: X — категориальная (текстовая или категориальная)
    if (xType == ColumnType.text || xType == ColumnType.categorical) {
      if (yType == ColumnType.text || yType == ColumnType.categorical) {
        // Обе категориальные — таблица сопряжённости
        return _buildContingencyTable(
          _toCategorical(xCol),
          _toCategorical(yCol),
        );
      } else if (yType == ColumnType.numeric) {
        // X категориальная, Y числовая — агрегация по X
        return _buildAggregationTable(
          _toCategorical(xCol),
          yCol as NumericColumn,
        );
      }
    }

    // Случай: Y — категориальная, X — числовая (меняем ролями)
    if (yType == ColumnType.text || yType == ColumnType.categorical) {
      if (xType == ColumnType.numeric) {
        return _buildAggregationTable(
          _toCategorical(yCol),
          xCol as NumericColumn,
        );
      }
    }

    // Если ничего не подошло
    throw Exception('Неподдерживаемая комбинация типов колонок для тепловой карты');
  }

  /// Асинхронно строит [HeatmapData] в отдельном изоляте.
  ///
  /// Используется для больших датасетов, чтобы не блокировать UI.
  /// Принимает [dataset] и [state], возвращает [Future<HeatmapData>].
  static Future<HeatmapData> computeAsync({
    required Dataset dataset,
    required HeatmapState state,
  }) async {
    // Извлекаем сырые значения колонок
    final xCol = state.xColumn != null ? dataset.column(state.xColumn!) : null;
    final yCol = state.yColumn != null ? dataset.column(state.yColumn!) : null;

    final xValues = xCol != null
        ? xCol.data.map((e) => e?.toString()).toList()
        : <String?>[];
    final yValues = yCol != null
        ? yCol.data.map((e) => e?.toString()).toList()
        : <String?>[];

    final params = _ComputationParams(
      xColumnName: state.xColumn,
      yColumnName: state.yColumn,
      xValues: xValues,
      yValues: yValues,
      aggregationType: state.aggregationType,
      clusterEnabled: state.clusterEnabled,
      sortX: state.sortX,
      sortY: state.sortY,
      normalizeMode: state.normalizeMode,
      percentageMode: state.percentageMode,
    );

    return await compute(_performComputation, params);
  }

  /// Статический метод, выполняемый в изоляте.
  static HeatmapData _performComputation(_ComputationParams params) {
    if (params.xColumnName == null && params.yColumnName == null) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    // Построение на основе сырых данных
    return _buildFromRaw(params);
  }

  /// Строит [HeatmapData] из сырых строковых списков (без доступа к Dataset).
  static HeatmapData _buildFromRaw(_ComputationParams params) {
    final xValues = params.xValues;
    final yValues = params.yValues;

    // Проверяем, что данные не пусты
    if (xValues.isEmpty || yValues.isEmpty) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    // Определяем типы колонок по содержимому (простейшая эвристика)
    final bool xIsNumeric = _isAllNumeric(xValues);
    final bool yIsNumeric = _isAllNumeric(yValues);

    // Обе числовые – не поддерживаем
    if (xIsNumeric && yIsNumeric) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    // Если одна из колонок числовая, а другая категориальная – агрегация
    if ((xIsNumeric && !yIsNumeric) || (!xIsNumeric && yIsNumeric)) {
      final catValues = !xIsNumeric ? xValues : yValues;
      final numValues = xIsNumeric ? xValues : yValues;

      final categories = _uniqueCategories(catValues);
      final limitedCategories = _limitCategories(categories, catValues);

      // Агрегируем
      final aggregated = _aggregateNumerical(
        catValues: catValues,
        numValues: numValues,
        categories: limitedCategories,
        aggType: params.aggregationType,
      );

      // Возвращаем матрицу с одной колонкой
      return HeatmapData(
        rowLabels: limitedCategories,
        columnLabels: [params.aggregationType.name],
        values: aggregated.map((v) => [v]).toList(),
      );
    }

    // Обе категориальные – таблица сопряжённости
    final xCats = _uniqueCategories(xValues);
    final yCats = _uniqueCategories(yValues);
    final limitedXCats = _limitCategories(xCats, xValues);
    final limitedYCats = _limitCategories(yCats, yValues);

    final matrix = List.generate(
      limitedXCats.length,
      (_) => List.filled(limitedYCats.length, 0.0),
    );

    for (int i = 0; i < xValues.length; i++) {
      final xv = xValues[i];
      final yv = yValues[i];
      if (xv == null || yv == null) continue;
      final xi = limitedXCats.indexOf(xv);
      final yi = limitedYCats.indexOf(yv);
      if (xi != -1 && yi != -1) {
        matrix[xi][yi] += 1;
      }
    }

    return HeatmapData(
      rowLabels: limitedXCats,
      columnLabels: limitedYCats,
      values: matrix,
    );
  }
  
  /// Строит таблицу сопряжённости для двух категориальных колонок
  ///
  /// Каждая ячейка матрицы содержит количество совместных появлений
  /// соответствующих категорий.
  ///
  /// Принимает:
  /// - [x] — первая категориальная колонка (строки матрицы)
  /// - [y] — вторая категориальная колонка (столбцы матрицы)
  ///
  /// Возвращает:
  /// - [HeatmapData] — матрица с частотами.
  HeatmapData _buildContingencyTable(CategoricalColumn x, CategoricalColumn y) {
    final xCategories = _uniqueCategories(x.data);
    final yCategories = _uniqueCategories(y.data);
    final limitedXCats = _limitCategories(xCategories, x.data);
    final limitedYCats = _limitCategories(yCategories, y.data);

    final matrix = List.generate(
      limitedXCats.length,
      (_) => List.filled(yCategories.length, 0.0),
    );

    for (int i = 0; i < x.length; i++) {
      final xv = x[i];
      final yv = y[i];
      if (xv == null || yv == null) continue;
      final xi = limitedXCats.indexOf(xv);
      final yi = limitedYCats.indexOf(yv);
      if (xi != -1 && yi != -1) {
        matrix[xi][yi] += 1;
      }
    }

    return HeatmapData(
      rowLabels: limitedXCats,
      columnLabels: limitedYCats,
      values: matrix,
    );
  }

  /// Строит агрегированные данные для пары "категориальная + числовая"
  ///
  /// Для каждой категории вычисляется значение в зависимости от выбранного
  /// типа агрегации ([AggregationType]):
  /// - [AggregationType.count] — количество значений в категории
  /// - [AggregationType.sum] — сумма числовых значений в категории
  /// - [AggregationType.avg] — среднее арифметическое
  /// - [AggregationType.min] — минимальное значение
  /// - [AggregationType.max] — максимальное значение
  ///
  /// Принимает:
  /// - [cat] — категориальная колонка (определяет строки)
  /// - [num] — числовая колонка (значения для агрегации)
  ///
  /// Возвращает:
  /// - [HeatmapData] — матрица с одной колонкой (значения по категориям).
  HeatmapData _buildAggregationTable(CategoricalColumn cat, NumericColumn num) {
    final categories = _uniqueCategories(cat.data);
    final limitedCategories = _limitCategories(categories, cat.data);
    final aggregated = _aggregateNumerical(
      catValues: cat.data,
      numValues: num.data.map((e) => e?.toString()).toList(),
      categories: limitedCategories,
      aggType: state.aggregationType,
    );

    // Возвращаем матрицу с одной колонкой (значения по категориям)
    return HeatmapData(
      rowLabels: categories,
      columnLabels: [state.aggregationType.name],
      values: aggregated.map((v) => [v]).toList(),
    );
  }
  
  static bool _isAllNumeric(List<String?> values) {
    for (final v in values) {
      if (v != null && double.tryParse(v) == null) return false;
    }
    return true;
  }

  /// Ограничивает количество категорий, оставляя наиболее частые.
  ///
  /// Если количество уникальных категорий превышает [maxUniqueCategories],
  /// возвращает только [maxUniqueCategories] самых частых.
  static List<String> _limitCategories(List<String> all, List<String?> data) {
    if (all.length <= maxUniqueCategories) return all;

    final freq = <String, int>{};
    for (final v in data) {
      if (v != null) freq[v] = (freq[v] ?? 0) + 1;
    }

    final sorted = List<String>.from(all)
      ..sort((a, b) => (freq[b] ?? 0).compareTo(freq[a] ?? 0));
    return sorted.take(maxUniqueCategories).toList();
  }

  /// Вычисляет агрегированное значение для каждой категории
  static List<double> _aggregateNumerical({
    required List<String?> catValues,
    required List<String?> numValues,
    required List<String> categories,
    required AggregationType aggType,
  }) {
    final counts = List.filled(categories.length, 0);
    final sums = List.filled(categories.length, 0.0);
    final mins = List.filled(categories.length, double.infinity);
    final maxs = List.filled(categories.length, -double.infinity);
    final medians = List.filled(categories.length, <double>[]);

    for (int i = 0; i < catValues.length; i++) {
      final c = catValues[i];
      final nStr = numValues[i];
      if (c == null || nStr == null) continue;
      final n = double.tryParse(nStr);
      if (n == null) continue;

      final idx = categories.indexOf(c);
      if (idx == -1) continue;

      counts[idx]++;
      sums[idx] += n;
      medians[idx].add(n);
      if (n < mins[idx]) mins[idx] = n;
      if (n > maxs[idx]) maxs[idx] = n;
    }

    final values = List.filled(categories.length, 0.0);
    for (int i = 0; i < categories.length; i++) {
      switch (aggType) {
        case AggregationType.count:
          values[i] = counts[i].toDouble();
          break;
        case AggregationType.sum:
          values[i] = sums[i];
          break;
        case AggregationType.avg:
          values[i] = counts[i] > 0 ? sums[i] / counts[i] : 0;
          break;
        case AggregationType.min:
          values[i] = counts[i] > 0 ? mins[i] : 0;
          break;
        case AggregationType.max:
          values[i] = counts[i] > 0 ? maxs[i] : 0;
          break;
        case AggregationType.median:
          final list = medians[i];
          if (list.isEmpty) {
            values[i] = 0;
          } else {
            list.sort();
            final mid = list.length ~/ 2;
            if (list.length % 2 == 0) {
              values[i] = (list[mid - 1] + list[mid]) / 2;
            } else {
              values[i] = list[mid];
            }
          }
          break;
      }
    }
    return values;
  }

  /// Возвращает отсортированный список уникальных значений категориальной колонки
  ///
  /// Принимает:
  /// - [col] — категориальная колонка.
  ///
  /// Возвращает:
  /// - [List<String>] — отсортированные по алфавиту уникальные значения.
  static List<String> _uniqueCategories(List<String?> data) {
    final set = <String>{};
    for (final v in data) {
      if (v != null) set.add(v);
    }
    return set.toList()..sort();
  }

  /// Приводит [DataColumn] к [CategoricalColumn]
  ///
  /// Если колонка уже [CategoricalColumn], возвращает её.
  /// Если колонка [TextColumn], создаёт новый [CategoricalColumn] с теми же данными.
  /// В противном случае выбрасывает исключение.
  ///
  /// Принимает:
  /// - [col] — колонка для преобразования.
  ///
  /// Возвращает:
  /// - [CategoricalColumn] — категориальное представление колонки.
  ///
  /// Выбрасывает:
  /// - [Exception] — если колонку невозможно преобразовать.
  CategoricalColumn _toCategorical(DataColumn col) {
    if (col is CategoricalColumn) return col;
    if (col is TextColumn) {
      // Создаём CategoricalColumn из текстовой колонки
      return CategoricalColumn(col.name, col.data);
    }
    throw Exception('Невозможно преобразовать колонку ${col.name} в категориальную');
  }

  /// Определяет тип колонки из перечисления [ColumnType]
  ///
  /// Принимает:
  /// - [col] — колонка для анализа.
  ///
  /// Возвращает:
  /// - [ColumnType] — тип колонки.
  ///
  /// Выбрасывает:
  /// - [Exception] — если тип колонки неизвестен.
  ColumnType _getColumnType(DataColumn col) {
    switch (col.runtimeType) {
      case const (NumericColumn):
        return ColumnType.numeric;
      case const (DateTimeColumn):
        return ColumnType.dateTime;
      case const (CategoricalColumn):
        return ColumnType.categorical;
      case const (TextColumn):
        return ColumnType.text;
      default:
        throw Exception('Неизвестный тип колонки: ${col.name}');
    }
  }
}

/// {@template computation_params}
/// Параметры для передачи в isolate.
///
/// Содержит все необходимые данные для построения [HeatmapData] без доступа к [Dataset].
/// {@endtemplate}
class _ComputationParams {
  /// Имя колонки X 
  final String? xColumnName;

  /// Имя колонки Y 
  final String? yColumnName;

  /// Значения колонки X в виде строк
  final List<String?> xValues;

  /// Значения колонки Y в виде строк
  final List<String?> yValues;

  /// Тип агрегации для числовых данных
  final AggregationType aggregationType;

  /// Включена ли кластеризация
  final bool clusterEnabled;

  /// Режим сортировки строк
  final SortMode sortX;

  /// Режим сортировки столбцов
  final SortMode sortY;

  /// Режим нормализации
  final NormalizeMode normalizeMode;

  /// Режим процентов
  final PercentageMode percentageMode;

  _ComputationParams({
    this.xColumnName,
    this.yColumnName,
    required this.xValues,
    required this.yValues,
    required this.aggregationType,
    required this.clusterEnabled,
    required this.sortX,
    required this.sortY,
    required this.normalizeMode,
    required this.percentageMode,
  });
}