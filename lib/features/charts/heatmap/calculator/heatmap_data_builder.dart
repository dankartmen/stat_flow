import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import '../../chart_state.dart';
import '../model/correlation_clusterer.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_state.dart';
import '../model/correlation_matrix.dart';

/// {@template heatmap_data_builder}
/// Строитель данных для тепловой карты с поддержкой асинхронных вычислений
/// Реализует логику построения данных для тепловой карты в зависимости от выбранных осей и режима корреляции.
/// Включает оптимизации для больших датасетов, такие как сэмплирование категорий и использование isolate для тяжёлых вычислений.
/// {@endtemplate}
class HeatmapDataBuilder {
  /// Датасет, содержащий данные для построения тепловой карты
  final Dataset dataset;

  /// Текущее состояние графика (выбранные колонки, тип агрегации)
  final HeatmapState state;

  /// Максимальное количество уникальных категорий для отображения
  static const int maxUniqueCategories = 200;
  HeatmapDataBuilder({
    required this.dataset,
    required this.state
  });

  /// Асинхронное построение данных для тепловой карты с поддержкой isolate для тяжёлых вычислений
  /// 
  /// Логика построения:
  /// - Если включён режим корреляции, строит матрицу корреляции для всех числовых колонок и применяет трансформации
  /// - Если выбраны колонки, строит соответствующую таблицу (контингенцию для категориальных или агрегированную для числовой + категориальной) в isolate и применяет трансформации
  /// - Если колонки не выбраны, возвращает пустые данные
  /// - В случае ошибок при построении, возвращает пустые данные и логирует ошибку
  /// 
  /// Возвращает:
  /// - [HeatmapData] с рассчитанными значениями для отображения на тепловой карте
  Future<HeatmapData> buildAsync() async {
    if (state.useCorrelation) {
      final matrix = await CorrelationMatrix.fromDatasetAsync(dataset);
      var data = HeatmapData.fromCorrelation(matrix);
      data = await _applyTransformationsAsync(data);
      return data;
    }

    if (state.xColumn == null || state.yColumn == null) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    // Проверяем, что колонки существуют
    final xCol = dataset.column(state.xColumn!);
    final yCol = dataset.column(state.yColumn!);
    if (xCol == null || yCol == null) {
      log('Одна из колонок не найдена: x=${state.xColumn}, y=${state.yColumn}');
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
        final data = await _buildContingencyTableAsync(
          _toCategorical(xCol),
          _toCategorical(yCol),
        );
        return _applyTransformationsAsync(data);
      } else if (yType == ColumnType.numeric) {
        // X категориальная, Y числовая — агрегация по X
        final data = await _buildAggregationTableAsync(
          _toCategorical(xCol),
          yCol as NumericColumn,
        );
        return _applyTransformationsAsync(data);
      }
    }

    // Случай: Y — категориальная, X — числовая (меняем ролями)
    if (yType == ColumnType.text || yType == ColumnType.categorical) {
      if (xType == ColumnType.numeric) {
        final data = await _buildAggregationTableAsync(
          _toCategorical(yCol),
          xCol as NumericColumn,
        );
        return _applyTransformationsAsync(data);
      }
    }

    throw Exception('Неподдерживаемая комбинация типов колонок для тепловой карты');
  }

  /// Применяет выбранные пользователем трансформации к данным тепловой карты
  /// - Кластеризация (если включена)
  /// - Сортировка по осям X и Y (если выбрана)
  /// - Нормализация (если выбрана)
  /// - Преобразование в проценты (если выбрано)
  /// Принимает:
  /// - [data] — исходные данные тепловой карты для трансформации
  /// Возвращает:
  /// - Трансформированные данные тепловой карты, готовые для отображения
  Future<HeatmapData> _applyTransformationsAsync(HeatmapData data) async {
    if (state.clusterEnabled && state.useCorrelation) {
      data = await _clusterAsync(data);
    }
    if (state.sortX != SortMode.none) {
      data = await data.sortRowsAsync(state.sortX);
    }
    if (state.sortY != SortMode.none) {
      data = await data.sortColsAsync(state.sortY);
    }
    if (state.normalizeMode != NormalizeMode.none) {
      data = await data.normalizeAsync(state.normalizeMode);
    }
    if (state.percentageMode != PercentageMode.none) {
      data = await data.toPercentagesAsync(state.percentageMode);
    }
    return data;
  }

  Future<HeatmapData> _clusterAsync(HeatmapData data) async {
    final size = data.rowLabels.length;

    if (size < 50) {
      return CorrelationClusterer.clusterHeatmapData(data);
    }
    return await compute(_clusterInIsolate, data);
  }

  /// Асинхронная версия кластеризации данных тепловой карты в isolate для больших матриц
  static Future<HeatmapData> _clusterInIsolate(HeatmapData data) async {
    return CorrelationClusterer.clusterHeatmapData(data);
  }

  /// Асинхронные вспомогательные методы
  /// Построение таблицы сопряжённости для двух категориальных колонок в isolate
  /// Построение агрегированной таблицы для числовой + категориальной колонки в isolate 
  /// Принимают:
  /// - Для контингенции: две категориальные колонки (их названия и значения)
  /// - Для агрегации: одна категориальная и одна числовая колонка (их названия, значения и тип агрегации)
  /// Возвращают:
  /// - [HeatmapData] с рассчитанными значениями для отображения на тепловой карте
  Future<HeatmapData> _buildContingencyTableAsync(CategoricalColumn x, CategoricalColumn y) async {
    final params = _ContingencyParams(
      xName: x.name,
      yName: y.name,
      xValues: x.data,
      yValues: y.data,
    );
    return await compute(_buildContingencyTableIsolate, params);
  }

  Future<HeatmapData> _buildAggregationTableAsync(CategoricalColumn cat, NumericColumn num) async {
    final params = _AggregationParams(
      catName: cat.name,
      numName: num.name,
      catValues: cat.data,
      numValues: num.data,
      aggType: state.aggregationType,
    );
    return await compute(_buildAggregationTableIsolate, params);
  }

  // Isolate-функции

  /// Isolate-функция для построения таблицы сопряжённости для двух категориальных колонок
  static HeatmapData _buildContingencyTableIsolate(_ContingencyParams params) {
    final xCategories = _uniqueCategories(params.xValues);
    final yCategories = _uniqueCategories(params.yValues);
    final limitedXCats = _limitCategories(xCategories, params.xValues);
    final limitedYCats = _limitCategories(yCategories, params.yValues);
    final matrix = List.generate(
      limitedXCats.length,
      (_) => List.filled(limitedYCats.length, 0.0),
    );
    for (int i = 0; i < params.xValues.length; i++) {
      final xv = params.xValues[i];
      final yv = params.yValues[i];
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

  /// Isolate-функция для построения агрегированной таблицы для числовой + категориальной колонки
  static HeatmapData _buildAggregationTableIsolate(_AggregationParams params) {
    final categories = _uniqueCategories(params.catValues);
    final limitedCategories = _limitCategories(categories, params.catValues);
    final aggregated = _aggregateNumerical(
      catValues: params.catValues,
      numValues: params.numValues.map((e) => e?.toString()).toList(),
      categories: limitedCategories,
      aggType: params.aggType,
    );
    return HeatmapData(
      rowLabels: limitedCategories,
      columnLabels: [params.aggType.name],
      values: aggregated.map((v) => [v]).toList(),
    );
  }

  // Вспомогательные методы для обработки категориальных данных и агрегации числовых данных
  
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

  static List<String> _limitCategories(List<String> all, List<String?> data) {
    if (all.length <= maxUniqueCategories) return all;
    final freq = <String, int>{};
    for (final v in data) if (v != null) freq[v] = (freq[v] ?? 0) + 1;
    final sorted = List<String>.from(all)
      ..sort((a, b) => (freq[b] ?? 0).compareTo(freq[a] ?? 0));
    return sorted.take(maxUniqueCategories).toList();
  }

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
    if (col is TextColumn) return CategoricalColumn(col.name, col.data);
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
class _ContingencyParams {
  /// Название колонки по оси X
  final String xName;
  /// Название колонки по оси Y
  final String yName;
  /// Значения колонок (может содержать null, который будет игнорироваться)
  final List<String?> xValues;
  /// Значения колонок (может содержать null, который будет игнорироваться)
  final List<String?> yValues;
  
  /// {@macro heatmap_isolate_params}
  _ContingencyParams({required this.xName, required this.yName, required this.xValues, required this.yValues});
}


/// {@template heatmap_aggregation_params}
/// Параметры для передачи в isolate при построении агрегированной тепловой карты (категориальная + числовая)
/// {@endtemplate}
class _AggregationParams {
  /// Название категориальной колонки
  final String catName;
  /// Название числовой колонки
  final String numName;
  /// Значения категориальной колонки (может содержать null, который будет игнорироваться)
  final List<String?> catValues;
  /// Значения числовой колонки (может содержать null, который будет игнорироваться)
  final List<double?> numValues;
  /// Тип агрегации (count, sum, avg, min, max, median)
  final AggregationType aggType;

  /// {@macro heatmap_aggregation_params}
  _AggregationParams({required this.catName, required this.numName, required this.catValues, required this.numValues, required this.aggType});
}