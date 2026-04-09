import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../../core/dataset/dataset.dart';
import '../calculator/heatmap_calculator.dart';

/// {@template correlation_matrix}
/// Класс, хранящий список полей и двумерный массив для матрицы корреляции
/// {@endtemplate}
class CorrelationMatrix {
  /// Список полей матрицы
  final List<String> fieldNames;

  /// Двумерный массив значений для быстрого доступа
  final List<List<double>> values;
  
  /// Кэш для быстрого поиска индекса по имени поля
  final Map<String, int> _indexMap;

  /// Кэш для доступа к столбцам (транспонированная матрица)
  List<List<double>>? _transposedCache;

  /// Флаг, указывающий, была ли матрица усечена для производительности
  final bool wasTrimmed;

  /// {@macro correlation_matrix}
  CorrelationMatrix(
    List<String> fieldNames,
    List<List<double>> values,{
    this.wasTrimmed = false,
    }
  ) : fieldNames = List.unmodifiable(fieldNames),
    values = List<List<double>>.unmodifiable(
      values.map((row) => List<double>.unmodifiable(row)),
    ),
    _indexMap = {
      for (int i = 0; i < fieldNames.length; i++)
        fieldNames[i]: i
    };

  /// Фабричный конструктор, строящий матрицу синхронно (для маленьких датасетов)
  factory CorrelationMatrix.fromDataset(Dataset dataset) {
    final numericColumns = dataset.numericColumns;
    if (numericColumns.length < 2) {
      return CorrelationMatrix([], []);
    }
    final names = numericColumns.map((c) => c.name).toList();
    final n = numericColumns.length;
    final values = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      values[i][i] = 1;
      for (int j = i + 1; j < n; j++) {
        final corr = HeatmapCalculator.calculatePearsonCorrelation(
          numericColumns[i].data,
          numericColumns[j].data,
        );
        values[i][j] = corr;
        values[j][i] = corr;
      }
    }
    return CorrelationMatrix(names, values);
  }

  /// Асинхронное построение матрицы в isolate (для больших датасетов)
  static Future<CorrelationMatrix> fromDatasetAsync(Dataset dataset) async {
    var numericColumns = dataset.numericColumns;
    const int maxColumns = 100;
    bool wasTrimmed = false;

    if (numericColumns.length > maxColumns) {
      numericColumns = _selectTopColumnsByVariance(numericColumns, maxColumns);
      wasTrimmed = true;
    }
    
    if (numericColumns.length < 2) {
      return CorrelationMatrix([], [], wasTrimmed: wasTrimmed);
    }

    final names = numericColumns.map((c) => c.name).toList();
    // Извлекаем сырые данные для передачи в isolate
    final columnsData = numericColumns.map((col) => col.data).toList();
    final matrix = await compute(_computeCorrelationMatrix, (names, columnsData));
    return CorrelationMatrix(names, matrix, wasTrimmed: wasTrimmed);
  }

  /// Выбирает топ колонок по дисперсии для ограничения размера матрицы (для больших датасетов)
  /// Используется в асинхронном методе построения матрицы корреляции для ограничения количества колонок до 100, чтобы избежать чрезмерной нагрузки на память и процессор при вычислении корреляций.
  static List<NumericColumn> _selectTopColumnsByVariance(List<NumericColumn> columns, int maxCount) {
    if (columns.length <= maxCount) return columns;
    
    final variances = columns.map((col) {
      final values = col.data.whereType<double>().toList();
      if (values.isEmpty) return 0.0;
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
      return variance;
    }).toList();
    
    final indices = List.generate(columns.length, (i) => i);
    indices.sort((a, b) => variances[b].compareTo(variances[a]));
    final selected = indices.take(maxCount).map((i) => columns[i]).toList();
    return selected;
  }

  /// Isolate-функция для вычисления корреляционной матрицы
  static List<List<double>> _computeCorrelationMatrix((List<String> names, List<List<double?>> columns) args) {
    final (names, columns) = args;
    final n = columns.length;
    final matrix = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      matrix[i][i] = 1.0;
      for (int j = i + 1; j < n; j++) {
        final corr = _pearsonCorrelation(columns[i], columns[j]);
        matrix[i][j] = corr;
        matrix[j][i] = corr;
      }
    }
    return matrix;
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
    final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    return denominator == 0 ? 0.0 : numerator / denominator;
  }

  /// Метод для получения значения матрицы по названию двух полей
  double get(String f1, String f2) {
    final i = _indexMap[f1]!;
    final j = _indexMap[f2]!;
    return values[i][j];
  }

  double getByIndex(int i, int j) => values[i][j];
  
  int get size => fieldNames.length;
  bool get isEmpty => fieldNames.isEmpty;
  bool contains(String fieldName) => _indexMap.containsKey(fieldName);
  List<double> row(int i) => values[i];
  
  /// Получение столбца по индексу
  List<double> column(int j) {
    _transposedCache ??= List.generate(
      values.length,
      (col) => List<double>.generate(values.length, (row) => values[row][col]),
    );
    return _transposedCache![j];
  }
}