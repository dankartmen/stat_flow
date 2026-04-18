import 'dart:math';

import 'package:flutter/foundation.dart';

import '../model/heatmap_data.dart';

/// {@template heatmap_data_builder}
/// Строитель для создания [HeatmapData] из различных источников.
/// Предоставляет фабричные методы для преобразования матриц, рядов, столбцов
/// и вычисления корреляционных матриц Пирсона.
/// {@endtemplate}
class HeatmapDataBuilder {
  /// {@macro heatmap_data_builder}
  const HeatmapDataBuilder._(); // Приватный конструктор, так как класс статический

  /// Создаёт [HeatmapData] из двумерного списка значений.
  ///
  /// [rowLabels] и [columnLabels] генерируются автоматически (Row 1, Col 1...),
  /// если не указаны явно.
  ///
  /// Принимает:
  /// - [values] - двумерный список значений типа double, где values[i][j] — значение в строке i, столбце j.
  /// - [rowLabels] - опциональный список строковых меток для строк.
  /// - [columnLabels] - опциональный список строковых меток для столбцов.
  ///
  /// Возвращает:
  /// - объект [HeatmapData] с заполненными метками и значениями.
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
  ///
  /// Принимает:
  /// - [rows] - список рядов, где каждый ряд — список значений double.
  /// - [rowLabels] - опциональные метки строк.
  /// - [columnLabels] - опциональные метки столбцов.
  ///
  /// Возвращает:
  /// - [HeatmapData], делегируя создание методу [fromMatrix].
  static HeatmapData fromRows(
    List<List<double>> rows, {
    List<String>? rowLabels,
    List<String>? columnLabels,
  }) {
    return fromMatrix(rows, rowLabels: rowLabels, columnLabels: columnLabels);
  }

  /// Создаёт [HeatmapData] из списка столбцов (каждый столбец — список значений).
  ///
  /// Принимает:
  /// - [columns] - список столбцов, где каждый столбец — список значений double.
  /// - [rowLabels] - опциональные метки строк.
  /// - [columnLabels] - опциональные метки столбцов.
  ///
  /// Возвращает:
  /// - [HeatmapData], где строки формируются из соответствующих элементов каждого столбца.
  ///
  /// Примечание: если columns пуст, возвращается пустой [HeatmapData].
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

    // Транспонирование: из списка столбцов формируем список строк
    final values = List.generate(rowCount, (i) {
      return List.generate(colCount, (j) => columns[j][i]);
    });

    return fromMatrix(values,
        rowLabels: rowLabels, columnLabels: columnLabels);
  }

  /// Вычисляет корреляционную матрицу Пирсона для переданных столбцов данных.
  ///
  /// Принимает:
  /// - [columns] - список списков значений с возможными null (пропуски будут исключены попарно).
  /// - [columnNames] - имена столбцов (если не указаны, генерируются как Var 1, Var 2...).
  ///
  /// Возвращает:
  /// - [HeatmapData] с симметричной корреляционной матрицей, где значения на диагонали равны 1.0.
  ///
  /// При ошибке (менее 2 столбцов) возвращается пустая матрица.
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
  ///
  /// Принимает:
  /// - [columns] - список списков значений с возможными null.
  /// - [columnNames] - опциональные имена столбцов.
  ///
  /// Возвращает:
  /// - [Future<HeatmapData>] - асинхронный результат корреляционной матрицы.
  ///
  /// Особенности работы:
  /// - При количестве столбцов > 30 или общем количестве элементов > 100000
  ///   вычисления выносятся в отдельный изолят через [compute] для сохранения производительности UI.
  /// - В остальных случаях используется синхронная версия [pearsonCorrelation].
  static Future<HeatmapData> pearsonCorrelationAsync(
    List<List<double?>> columns, {
    List<String>? columnNames,
  }) async {
    // Вычисляем общее количество элементов для оценки необходимости изолята
    final totalElements = columns.fold<int>(0, (sum, col) => sum + col.length);
    
    // Порог выбран эмпирически: >30 переменных или >100k наблюдений
    if (columns.length > 30 || totalElements > 100000) {
      return await compute(_pearsonCorrelationIsolate,
          _PearsonParams(columns, columnNames));
    }
    return pearsonCorrelation(columns, columnNames: columnNames);
  }

  /// Вычисляет коэффициент корреляции Пирсона между двумя рядами данных.
  ///
  /// Принимает:
  /// - [x] - первый ряд значений (может содержать null).
  /// - [y] - второй ряд значений (может содержать null).
  ///
  /// Возвращает:
  /// - коэффициент корреляции в диапазоне [-1, 1].
  /// - 0.0, если количество парных не-null значений меньше 2 или знаменатель равен 0.
  ///
  /// Формула: r = (n*Σxy - Σx*Σy) / sqrt((n*Σx² - (Σx)²) * (n*Σy² - (Σy)²))
  static double _pearsonCorrelation(List<double?> x, List<double?> y) {
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    int n = 0;

    // Попарное исключение null-значений (listwise deletion)
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

/// {@template pearson_params}
/// Параметры для передачи в изолят при вычислении корреляционной матрицы.
/// Содержит исходные данные и опциональные имена столбцов.
/// {@endtemplate}
class _PearsonParams {
  /// Список столбцов данных для корреляционного анализа.
  final List<List<double?>> columns;
  
  /// Опциональные имена столбцов.
  final List<String>? columnNames;

  /// {@macro pearson_params}
  _PearsonParams(this.columns, this.columnNames);
}

/// Функция для выполнения в изоляте при вычислении корреляционной матрицы.
///
/// Принимает:
/// - [params] - [_PearsonParams] с данными и именами столбцов.
///
/// Возвращает:
/// - [HeatmapData] с вычисленной корреляционной матрицей.
///
/// Примечание: эта функция должна быть топ-уровневой для корректной работы compute().
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