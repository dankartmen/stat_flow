import 'package:flutter/foundation.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';

/// Набор утилит для трансформации данных тепловой карты.
///
/// Все методы создают новую копию данных, не изменяя оригинал.
class HeatmapTransformer {
  /// Нормализует значения матрицы.
  ///
  /// - [NormalizeMode.row] — сумма абсолютных значений в строке = 1
  /// - [NormalizeMode.column] — сумма абсолютных значений в столбце = 1
  /// - [NormalizeMode.total] — сумма всех абсолютных значений = 1
  static HeatmapData normalize(HeatmapData data, NormalizeMode mode) {
    if (mode == NormalizeMode.none) return data;

    final newValues = data.values.map((row) => row.toList()).toList();

    switch (mode) {
      case NormalizeMode.row:
        for (int i = 0; i < newValues.length; i++) {
          final sum = newValues[i].fold(0.0, (s, v) => s + v.abs());
          if (sum != 0) {
            for (int j = 0; j < newValues[i].length; j++) {
              newValues[i][j] /= sum;
            }
          }
        }
        break;
      case NormalizeMode.column:
        for (int j = 0; j < newValues[0].length; j++) {
          double sum = 0.0;
          for (int i = 0; i < newValues.length; i++) {
            sum += newValues[i][j].abs();
          }
          if (sum != 0) {
            for (int i = 0; i < newValues.length; i++) {
              newValues[i][j] /= sum;
            }
          }
        }
        break;
      case NormalizeMode.total:
        final total =
            newValues.expand((row) => row).fold(0.0, (s, v) => s + v.abs());
        if (total != 0) {
          for (int i = 0; i < newValues.length; i++) {
            for (int j = 0; j < newValues[i].length; j++) {
              newValues[i][j] /= total;
            }
          }
        }
        break;
      case NormalizeMode.none:
        break;
    }

    return HeatmapData(
      rowLabels: data.rowLabels,
      columnLabels: data.columnLabels,
      values: newValues,
    );
  }

  /// Сортирует строки матрицы.
  ///
  /// - [SortMode.alphabetic] — по алфавиту подписей
  /// - [SortMode.byValueAsc] — по возрастанию суммы значений в строке
  /// - [SortMode.byValueDesc] — по убыванию суммы значений в строке
  static HeatmapData sortRows(HeatmapData data, SortMode mode) {
    if (mode == SortMode.none) return data;

    final indices = List.generate(data.rowLabels.length, (i) => i);
    switch (mode) {
      case SortMode.alphabetic:
        indices.sort((a, b) => data.rowLabels[a].compareTo(data.rowLabels[b]));
        break;
      case SortMode.byValueAsc:
        indices.sort((a, b) => data.values[a].reduce((x, y) => x + y)
            .compareTo(data.values[b].reduce((x, y) => x + y)));
        break;
      case SortMode.byValueDesc:
        indices.sort((a, b) => data.values[b].reduce((x, y) => x + y)
            .compareTo(data.values[a].reduce((x, y) => x + y)));
        break;
      case SortMode.none:
        break;
    }

    return HeatmapData(
      rowLabels: indices.map((i) => data.rowLabels[i]).toList(),
      columnLabels: data.columnLabels,
      values: indices.map((i) => data.values[i]).toList(),
    );
  }

  /// Сортирует столбцы матрицы.
  ///
  /// - [SortMode.alphabetic] — по алфавиту подписей
  /// - [SortMode.byValueAsc] — по возрастанию суммы абсолютных значений в столбце
  /// - [SortMode.byValueDesc] — по убыванию суммы абсолютных значений в столбце
  static HeatmapData sortCols(HeatmapData data, SortMode mode) {
    if (mode == SortMode.none) return data;

    final indices = List.generate(data.columnLabels.length, (i) => i);

    if (mode == SortMode.alphabetic) {
      indices.sort(
          (a, b) => data.columnLabels[a].compareTo(data.columnLabels[b]));
    } else {
      final colSums = List.generate(data.columnLabels.length, (j) {
        double sum = 0.0;
        for (int i = 0; i < data.values.length; i++) {
          sum += data.values[i][j].abs();
        }
        return sum;
      });

      if (mode == SortMode.byValueAsc) {
        indices.sort((a, b) => colSums[a].compareTo(colSums[b]));
      } else if (mode == SortMode.byValueDesc) {
        indices.sort((a, b) => colSums[b].compareTo(colSums[a]));
      }
    }

    return HeatmapData(
      rowLabels: data.rowLabels,
      columnLabels: indices.map((i) => data.columnLabels[i]).toList(),
      values: data.values
          .map((row) => indices.map((i) => row[i]).toList())
          .toList(),
    );
  }

  /// Преобразует значения в проценты от суммы по строке, столбцу или общей суммы.
  static HeatmapData toPercentages(HeatmapData data, PercentageMode mode) {
    if (mode == PercentageMode.none) return data;

    final newValues = data.values.map((row) => row.toList()).toList();

    switch (mode) {
      case PercentageMode.row:
        for (int i = 0; i < newValues.length; i++) {
          final rowSum = newValues[i].fold(0.0, (a, b) => a + b);
          if (rowSum != 0) {
            for (int j = 0; j < newValues[i].length; j++) {
              newValues[i][j] = newValues[i][j] / rowSum * 100;
            }
          }
        }
        break;
      case PercentageMode.column:
        for (int j = 0; j < newValues[0].length; j++) {
          double colSum = 0.0;
          for (int i = 0; i < newValues.length; i++) {
            colSum += newValues[i][j];
          }
          if (colSum != 0) {
            for (int i = 0; i < newValues.length; i++) {
              newValues[i][j] = newValues[i][j] / colSum * 100;
            }
          }
        }
        break;
      case PercentageMode.total:
        final total =
            newValues.expand((row) => row).fold(0.0, (a, b) => a + b);
        if (total != 0) {
          for (int i = 0; i < newValues.length; i++) {
            for (int j = 0; j < newValues[i].length; j++) {
              newValues[i][j] = newValues[i][j] / total * 100;
            }
          }
        }
        break;
      case PercentageMode.none:
        break;
    }

    return HeatmapData(
      rowLabels: data.rowLabels,
      columnLabels: data.columnLabels,
      values: newValues,
    );
  }

  /// Кластеризует матрицу, переупорядочивая строки и столбцы на основе сумм
  /// абсолютных значений (чем больше сумма, тем выше позиция).
  ///
  /// Работает только для квадратных матриц (например, корреляционных).
  /// Если матрица не квадратная, возвращает исходные данные.
  static HeatmapData cluster(HeatmapData data) {
    if (data.rowLabels.length != data.columnLabels.length) {
      return data;
    }

    final size = data.rowLabels.length;
    final indices = List.generate(size, (i) => i);

    // Рассчитываем суммы абсолютных значений для каждой строки
    final sums = List.generate(size, (row) {
      double s = 0.0;
      for (int col = 0; col < size; col++) {
        s += data.values[row][col].abs();
      }
      return s;
    });

    // Сортируем индексы по убыванию сумм
    indices.sort((a, b) => sums[b].compareTo(sums[a]));

    return HeatmapData(
      rowLabels: indices.map((i) => data.rowLabels[i]).toList(),
      columnLabels: indices.map((i) => data.columnLabels[i]).toList(),
      values: List.generate(size, (i) {
        final row = indices[i];
        return List.generate(size, (j) => data.values[row][indices[j]]);
      }),
    );
  }

  // --- Асинхронные версии для больших матриц ---

  /// Асинхронная нормализация (использует isolate для матриц > 50,000 ячеек).
  static Future<HeatmapData> normalizeAsync(
      HeatmapData data, NormalizeMode mode) async {
    if (mode == NormalizeMode.none) return data;
    final totalCells = data.rowLabels.length * data.columnLabels.length;
    if (totalCells < 50000) return normalize(data, mode);

    return await compute(_normalizeInIsolate,
        _IsolateParams(data.rowLabels, data.columnLabels, data.values, mode));
  }

  /// Асинхронная сортировка строк.
  static Future<HeatmapData> sortRowsAsync(
      HeatmapData data, SortMode mode) async {
    if (mode == SortMode.none) return data;
    final totalCells = data.rowLabels.length * data.columnLabels.length;
    if (totalCells < 50000) return sortRows(data, mode);

    return await compute(_sortRowsInIsolate,
        _IsolateParams(data.rowLabels, data.columnLabels, data.values, mode));
  }

  /// Асинхронная сортировка столбцов.
  static Future<HeatmapData> sortColsAsync(
      HeatmapData data, SortMode mode) async {
    if (mode == SortMode.none) return data;
    final totalCells = data.rowLabels.length * data.columnLabels.length;
    if (totalCells < 50000) return sortCols(data, mode);

    return await compute(_sortColsInIsolate,
        _IsolateParams(data.rowLabels, data.columnLabels, data.values, mode));
  }

  /// Асинхронное преобразование в проценты.
  static Future<HeatmapData> toPercentagesAsync(
      HeatmapData data, PercentageMode mode) async {
    if (mode == PercentageMode.none) return data;
    final totalCells = data.rowLabels.length * data.columnLabels.length;
    if (totalCells < 50000) return toPercentages(data, mode);

    return await compute(_percentagesInIsolate,
        _IsolateParams(data.rowLabels, data.columnLabels, data.values, mode));
  }

  /// Асинхронная кластеризация.
  static Future<HeatmapData> clusterAsync(HeatmapData data) async {
    if (data.rowLabels.length != data.columnLabels.length) return data;
    final size = data.rowLabels.length;
    if (size < 50) return cluster(data);

    return await compute(_clusterInIsolate,
        _IsolateParams(data.rowLabels, data.columnLabels, data.values, null));
  }
}

// Вспомогательный класс для передачи параметров в isolate
class _IsolateParams {
  final List<String> rowLabels;
  final List<String> columnLabels;
  final List<List<double>> values;
  final dynamic mode; // NormalizeMode, SortMode, PercentageMode или null

  _IsolateParams(this.rowLabels, this.columnLabels, this.values, this.mode);
}

HeatmapData _normalizeInIsolate(_IsolateParams params) {
  final mode = params.mode as NormalizeMode;
  final newValues = params.values.map((row) => row.toList()).toList();

  switch (mode) {
    case NormalizeMode.row:
      for (int i = 0; i < newValues.length; i++) {
        final sum = newValues[i].fold(0.0, (s, v) => s + v.abs());
        if (sum != 0) {
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] /= sum;
          }
        }
      }
      break;
    case NormalizeMode.column:
      for (int j = 0; j < newValues[0].length; j++) {
        double sum = 0.0;
        for (int i = 0; i < newValues.length; i++) {
          sum += newValues[i][j].abs();
        }
        if (sum != 0) {
          for (int i = 0; i < newValues.length; i++) {
            newValues[i][j] /= sum;
          }
        }
      }
      break;
    case NormalizeMode.total:
      final total =
          newValues.expand((row) => row).fold(0.0, (s, v) => s + v.abs());
      if (total != 0) {
        for (int i = 0; i < newValues.length; i++) {
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] /= total;
          }
        }
      }
      break;
    case NormalizeMode.none:
      break;
  }

  return HeatmapData(
    rowLabels: params.rowLabels,
    columnLabels: params.columnLabels,
    values: newValues,
  );
}

HeatmapData _sortRowsInIsolate(_IsolateParams params) {
  final mode = params.mode as SortMode;
  final indices = List.generate(params.rowLabels.length, (i) => i);

  switch (mode) {
    case SortMode.alphabetic:
      indices.sort(
          (a, b) => params.rowLabels[a].compareTo(params.rowLabels[b]));
      break;
    case SortMode.byValueAsc:
      indices.sort((a, b) => params.values[a].reduce((x, y) => x + y)
          .compareTo(params.values[b].reduce((x, y) => x + y)));
      break;
    case SortMode.byValueDesc:
      indices.sort((a, b) => params.values[b].reduce((x, y) => x + y)
          .compareTo(params.values[a].reduce((x, y) => x + y)));
      break;
    case SortMode.none:
      break;
  }

  return HeatmapData(
    rowLabels: indices.map((i) => params.rowLabels[i]).toList(),
    columnLabels: params.columnLabels,
    values: indices.map((i) => params.values[i]).toList(),
  );
}

HeatmapData _sortColsInIsolate(_IsolateParams params) {
  final mode = params.mode as SortMode;
  final indices = List.generate(params.columnLabels.length, (i) => i);

  if (mode == SortMode.alphabetic) {
    indices.sort(
        (a, b) => params.columnLabels[a].compareTo(params.columnLabels[b]));
  } else {
    final colSums = List.generate(params.columnLabels.length, (j) {
      double sum = 0.0;
      for (int i = 0; i < params.values.length; i++) {
        sum += params.values[i][j].abs();
      }
      return sum;
    });

    if (mode == SortMode.byValueAsc) {
      indices.sort((a, b) => colSums[a].compareTo(colSums[b]));
    } else if (mode == SortMode.byValueDesc) {
      indices.sort((a, b) => colSums[b].compareTo(colSums[a]));
    }
  }

  return HeatmapData(
    rowLabels: params.rowLabels,
    columnLabels: indices.map((i) => params.columnLabels[i]).toList(),
    values: params.values
        .map((row) => indices.map((i) => row[i]).toList())
        .toList(),
  );
}

HeatmapData _percentagesInIsolate(_IsolateParams params) {
  final mode = params.mode as PercentageMode;
  final newValues = params.values.map((row) => row.toList()).toList();

  switch (mode) {
    case PercentageMode.row:
      for (int i = 0; i < newValues.length; i++) {
        final rowSum = newValues[i].fold(0.0, (a, b) => a + b);
        if (rowSum != 0) {
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] = newValues[i][j] / rowSum * 100;
          }
        }
      }
      break;
    case PercentageMode.column:
      for (int j = 0; j < newValues[0].length; j++) {
        double colSum = 0.0;
        for (int i = 0; i < newValues.length; i++) {
          colSum += newValues[i][j];
        }
        if (colSum != 0) {
          for (int i = 0; i < newValues.length; i++) {
            newValues[i][j] = newValues[i][j] / colSum * 100;
          }
        }
      }
      break;
    case PercentageMode.total:
      final total = newValues.expand((row) => row).fold(0.0, (a, b) => a + b);
      if (total != 0) {
        for (int i = 0; i < newValues.length; i++) {
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] = newValues[i][j] / total * 100;
          }
        }
      }
      break;
    case PercentageMode.none:
      break;
  }

  return HeatmapData(
    rowLabels: params.rowLabels,
    columnLabels: params.columnLabels,
    values: newValues,
  );
}

HeatmapData _clusterInIsolate(_IsolateParams params) {
  final size = params.rowLabels.length;
  final indices = List.generate(size, (i) => i);

  final sums = List.generate(size, (row) {
    double s = 0.0;
    for (int col = 0; col < size; col++) {
      s += params.values[row][col].abs();
    }
    return s;
  });

  indices.sort((a, b) => sums[b].compareTo(sums[a]));

  return HeatmapData(
    rowLabels: indices.map((i) => params.rowLabels[i]).toList(),
    columnLabels: indices.map((i) => params.columnLabels[i]).toList(),
    values: List.generate(size, (i) {
      final row = indices[i];
      return List.generate(size, (j) => params.values[row][indices[j]]);
    }),
  );
}