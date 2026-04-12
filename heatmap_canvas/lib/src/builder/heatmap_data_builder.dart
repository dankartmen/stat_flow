import 'dart:math';

import 'package:flutter/foundation.dart';

import '../model/heatmap_data.dart';

/// Строитель для создания [HeatmapData] из различных источников.
class HeatmapDataBuilder {
  /// Создаёт [HeatmapData] из двумерного списка значений.
  ///
  /// [rowLabels] и [columnLabels] могут быть сгенерированы автоматически,
  /// если не указаны.
  static HeatmapData fromMatrix(
    List<List<double>> values, {
    List<String>? rowLabels,
    List<String>? columnLabels,
  }) {
    final rows = rowLabels ??
        List.generate(values.length, (i) => 'Row ${i + 1}');
    final cols = columnLabels ??
        List.generate(
            values.isNotEmpty ? values[0].length : 0, (i) => 'Col ${i + 1}');

    return HeatmapData(
      rowLabels: rows,
      columnLabels: cols,
      values: values,
    );
  }

  /// Создаёт [HeatmapData] из списка рядов (каждый ряд — список значений).
  static HeatmapData fromRows(
    List<List<double>> rows, {
    List<String>? rowLabels,
    List<String>? columnLabels,
  }) {
    return fromMatrix(rows, rowLabels: rowLabels, columnLabels: columnLabels);
  }

  /// Создаёт [HeatmapData] из списка столбцов (каждый столбец — список значений).
  static HeatmapData fromColumns(
    List<List<double>> columns, {
    List<String>? rowLabels,
    List<String>? columnLabels,
  }) {
    if (columns.isEmpty) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    final rowCount = columns[0].length;
    final colCount = columns.length;

    final values = List.generate(rowCount, (i) {
      return List.generate(colCount, (j) => columns[j][i]);
    });

    return fromMatrix(values,
        rowLabels: rowLabels, columnLabels: columnLabels);
  }

  /// Вычисляет корреляционную матрицу Пирсона для переданных столбцов данных.
  ///
  /// [columns] — список списков значений (могут быть null).
  /// [columnNames] — имена столбцов (если не указаны, генерируются).
  static HeatmapData pearsonCorrelation(
    List<List<double?>> columns, {
    List<String>? columnNames,
  }) {
    if (columns.length < 2) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    final names = columnNames ??
        List.generate(columns.length, (i) => 'Var ${i + 1}');
    final n = columns.length;
    final values = List.generate(n, (_) => List.filled(n, 0.0));

    for (int i = 0; i < n; i++) {
      values[i][i] = 1.0;
      for (int j = i + 1; j < n; j++) {
        final corr = _pearsonCorrelation(columns[i], columns[j]);
        values[i][j] = corr;
        values[j][i] = corr;
      }
    }

    return HeatmapData(
      rowLabels: names,
      columnLabels: names,
      values: values,
    );
  }

  /// Асинхронная версия вычисления корреляционной матрицы (для больших данных).
  static Future<HeatmapData> pearsonCorrelationAsync(
    List<List<double?>> columns, {
    List<String>? columnNames,
  }) async {
    // Если столбцов много (> 30) или данных много, используем isolate
    if (columns.length > 30 ||
        columns.fold<int>(0, (sum, col) => sum + col.length) > 100000) {
      return await compute(_pearsonCorrelationIsolate,
          _PearsonParams(columns, columnNames));
    }
    return pearsonCorrelation(columns, columnNames: columnNames);
  }

  static double _pearsonCorrelation(List<double?> x, List<double?> y) {
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    int n = 0;

    for (int i = 0; i < x.length; i++) {
      final xi = x[i];
      final yi = y[i];
      if (xi == null || yi == null) continue;
      sumX += xi;
      sumY += yi;
      sumXY += xi * yi;
      sumX2 += xi * xi;
      sumY2 += yi * yi;
      n++;
    }

    if (n < 2) return 0.0;
    final numerator = n * sumXY - sumX * sumY;
    final denominator =
        sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    return denominator == 0 ? 0.0 : numerator / denominator;
  }
}

// Параметры для isolate
class _PearsonParams {
  final List<List<double?>> columns;
  final List<String>? columnNames;

  _PearsonParams(this.columns, this.columnNames);
}

HeatmapData _pearsonCorrelationIsolate(_PearsonParams params) {
  final columns = params.columns;
  final names = params.columnNames ??
      List.generate(columns.length, (i) => 'Var ${i + 1}');
  final n = columns.length;
  final values = List.generate(n, (_) => List.filled(n, 0.0));

  for (int i = 0; i < n; i++) {
    values[i][i] = 1.0;
    for (int j = i + 1; j < n; j++) {
      final corr = HeatmapDataBuilder._pearsonCorrelation(columns[i], columns[j]);
      values[i][j] = corr;
      values[j][i] = corr;
    }
  }

  return HeatmapData(
    rowLabels: names,
    columnLabels: names,
    values: values,
  );
}