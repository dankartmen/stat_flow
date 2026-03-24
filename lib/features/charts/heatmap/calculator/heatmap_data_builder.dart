import 'dart:developer';

import 'package:stat_flow/core/dataset/dataset.dart';
import '../../chart_state.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_state.dart';


class HeatmapDataBuilder {
  final Dataset dataset;
  final HeatmapState state;

  HeatmapDataBuilder(this.dataset, this.state);

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

  /// Таблица сопряжённости (counts) для двух категориальных колонок
  HeatmapData _buildContingencyTable(CategoricalColumn x, CategoricalColumn y) {
    final xCategories = _uniqueCategories(x);
    final yCategories = _uniqueCategories(y);
    
    final matrix = List.generate(
      xCategories.length,
      (_) => List.filled(yCategories.length, 0.0),
    );

    for (int i = 0; i < x.length; i++) {
      final xv = x[i];
      final yv = y[i];
      if (xv == null || yv == null) continue;
      final xi = xCategories.indexOf(xv);
      final yi = yCategories.indexOf(yv);
      if (xi != -1 && yi != -1) {
        matrix[xi][yi] += 1;
      }
    }

    return HeatmapData(
      rowLabels: xCategories,
      columnLabels: yCategories,
      values: matrix,
    );
  }

  /// Агрегация: категориальная колонка (cat) и числовая (num)
  HeatmapData _buildAggregationTable(CategoricalColumn cat, NumericColumn num) {
    final categories = _uniqueCategories(cat);
    final counts = List.filled(categories.length, 0);
    final sums = List.filled(categories.length, 0.0);
    final mins = List.filled(categories.length, double.infinity);
    final maxs = List.filled(categories.length, -double.infinity);

    for (int i = 0; i < cat.length; i++) {
      final c = cat[i];
      final n = num[i];
      if (c == null || n == null) continue;
      final idx = categories.indexOf(c);
      if (idx == -1) continue;

      counts[idx]++;
      sums[idx] += n;
      if (n < mins[idx]) mins[idx] = n;
      if (n > maxs[idx]) maxs[idx] = n;
    }

    // Вычисляем итоговые значения в зависимости от выбранной агрегации
    final values = List.filled(categories.length, 0.0);
    for (int i = 0; i < categories.length; i++) {
      switch (state.aggregationType) {
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
      }
    }

    // Возвращаем матрицу с одной колонкой (значения по категориям)
    return HeatmapData(
      rowLabels: categories,
      columnLabels: [state.aggregationType.name],
      values: values.map((v) => [v]).toList(),
    );
  }

  /// Получить уникальные значения из категориальной колонки (сортированные)
  List<String> _uniqueCategories(CategoricalColumn col) {
    final set = <String>{};
    for (final v in col.data) {
      if (v != null) set.add(v);
    }
    return set.toList()..sort();
  }

  /// Приведение DataColumn к CategoricalColumn (если это TextColumn, конвертируем)
  CategoricalColumn _toCategorical(DataColumn col) {
    if (col is CategoricalColumn) return col;
    if (col is TextColumn) {
      // Создаём CategoricalColumn из текстовой колонки
      return CategoricalColumn(col.name, col.data);
    }
    throw Exception('Невозможно преобразовать колонку ${col.name} в категориальную');
  }

  ColumnType _getColumnType(DataColumn col) {
    if (col is NumericColumn) return ColumnType.numeric;
    if (col is DateTimeColumn) return ColumnType.dateTime;
    if (col is CategoricalColumn) return ColumnType.categorical;
    if (col is TextColumn) return ColumnType.text;
    throw Exception('Неизвестный тип колонки');
  }
}