import 'package:flutter/foundation.dart';
import 'heatmap_config.dart';

/// {@template heatmap_data}
/// Модель данных для отображения тепловой карты
/// 
/// Представляет собой двумерную матрицу значений с подписями строк и столбцов.
/// Отвечает за:
/// - Хранение матрицы значений тепловой карты
/// - Вычисление минимального и максимального значений для цветовой шкалы
/// - Нормализацию данных (по строкам, столбцам или общую)
/// - Сортировку строк и столбцов по различным критериям
/// - Создание данных из корреляционной матрицы
/// 
/// Используется для визуализации:
/// - Корреляционных матриц (симметричных)
/// - Таблиц сопряженности
/// - Любых двумерных числовых данных
/// {@endtemplate}
class HeatmapData {
  /// Подписи строк
  final List<String> rowLabels;
  
  /// Подписи столбцов
  final List<String> columnLabels;
  
  /// Двумерная матрица значений для отображения
  final List<List<double>> values;

  /// Кэш для минимального и максимального значения
  double? _cachedMin;
  double? _cachedMax;

  /// Минимальное значение 
  double get min {
    _cachedMin ??= values.expand((v) => v).reduce((a, b) => a < b ? a : b);
    return _cachedMin!;
  }

  /// Максимальное значение
  double get max {
    _cachedMax ??= values.expand((v) => v).reduce((a, b) => a > b ? a : b);
    return _cachedMax!;
  }

  HeatmapData({
    required this.rowLabels,
    required this.columnLabels,
    required this.values,
  });

  

  /// Применяет нормализацию к значениям матрицы
  /// 
  /// Поддерживаемые режимы нормализации:
  /// - [NormalizeMode.none] — без изменений
  /// - [NormalizeMode.row] — сумма абсолютных значений в строке = 1
  /// - [NormalizeMode.column] — сумма абсолютных значений в столбце = 1
  /// - [NormalizeMode.total] — сумма всех абсолютных значений = 1
  /// 
  /// Нормализация полезна для:
  /// - Сравнения относительных вкладов в строке/столбце
  /// - Выявления паттернов при разных масштабах данных
  /// - Подготовки данных для кластеризации
  /// 
  /// Возвращает:
  /// - [HeatmapData] — новый экземпляр с нормализованными значениями
  HeatmapData normalize(NormalizeMode mode) {
    if (mode == NormalizeMode.none) return this;
    final newValues = values.map((row) => row.toList()).toList();
    if (mode == NormalizeMode.row || mode == NormalizeMode.column) {
      if (mode == NormalizeMode.row) {
        // Нормализация по строкам: каждая строка делится на сумму абсолютных значений
        for (int i = 0; i < newValues.length; i++) {
          double sum = 0;
          for (var v in newValues[i]) {
            sum += v.abs();
          }
          if (sum == 0) continue;
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] /= sum;
          }
        }
      } else {
        // Нормализация по столбцам: каждый столбец делится на сумму абсолютных значений
        for (int j = 0; j < newValues[0].length; j++) {
          double sum = 0;
          for (var row in newValues) {
            sum += row[j].abs();
          }
          if (sum == 0) continue;
          for (int i = 0; i < newValues.length; i++) {
            newValues[i][j] /= sum;
          }
        }
      }
    } else if (mode == NormalizeMode.total) {
      // Общая нормализация: все значения делятся на общую сумму
      double total = newValues.expand((e) => e).fold(0.0, (s, v) => s + v.abs());
      if (total != 0) {
        for (int i = 0; i < newValues.length; i++) {
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] /= total;
          }
        }
      }
    }

    return HeatmapData(
      rowLabels: rowLabels,
      columnLabels: columnLabels,
      values: newValues,
    );
  }

  /// Сортирует строки матрицы по указанному критерию
  /// 
  /// Режимы сортировки:
  /// - [SortMode.none] — без изменений
  /// - [SortMode.alphabetic] — по алфавиту подписей строк
  /// - [SortMode.byValueAsc] — по возрастанию суммы значений в строке
  /// - [SortMode.byValueDesc] — по убыванию суммы значений в строке
  /// 
  /// Сортировка позволяет:
  /// - Выявлять кластеры схожих строк
  /// - Улучшать читаемость тепловой карты
  /// - Группировать похожие паттерны
  /// 
  /// Возвращает:
  /// - [HeatmapData] — новый экземпляр с отсортированными строками
  HeatmapData sortRows(SortMode mode) {
    if (mode == SortMode.none) return this;
    List<int> indices = List.generate(rowLabels.length, (i) => i);
    switch (mode) {
      case SortMode.alphabetic:
        indices.sort((a, b) => rowLabels[a].compareTo(rowLabels[b]));
        break;
      case SortMode.byValueAsc:
        indices.sort((a, b) => values[a].reduce((x, y) => x + y)
            .compareTo(values[b].reduce((x, y) => x + y)));
        break;
      case SortMode.byValueDesc:
        indices.sort((a, b) => values[b].reduce((x, y) => x + y)
            .compareTo(values[a].reduce((x, y) => x + y)));
        break;
      default:
    }
    return HeatmapData(
      rowLabels: indices.map((i) => rowLabels[i]).toList(),
      columnLabels: columnLabels,
      values: indices.map((i) => values[i]).toList(),
    );
  }

  /// Сортирует столбцы матрицы по указанному критерию
  /// 
  /// Режимы сортировки:
  /// - [SortMode.none] — без изменений
  /// - [SortMode.alphabetic] — по алфавиту подписей столбцов
  /// - [SortMode.byValueAsc] — по возрастанию суммы абсолютных значений в столбце
  /// - [SortMode.byValueDesc] — по убыванию суммы абсолютных значений в столбце
  /// 
  /// Сортировка позволяет:
  /// - Выявлять кластеры схожих столбцов
  /// - Улучшать читаемость тепловой карты
  /// - Группировать коррелирующие признаки
  /// 
  /// Возвращает:
  /// - [HeatmapData] — новый экземпляр с отсортированными столбцами
  HeatmapData sortCols(SortMode mode) {
    if (mode == SortMode.none) return this;

    List<int> indices = List.generate(columnLabels.length, (i) => i);

    if (mode == SortMode.alphabetic) {
      indices.sort((a, b) => columnLabels[a].compareTo(columnLabels[b]));
    } else {
      // Вычисляем сумму абсолютных значений для каждого столбца
      List<double> colSums = List.generate(columnLabels.length, (j) {
        double s = 0;
        for (var row in values) {
          s += row[j].abs();
        }
        return s;
      });

      if (mode == SortMode.byValueAsc) {
        indices.sort((a, b) => colSums[a].compareTo(colSums[b]));
      } else if (mode == SortMode.byValueDesc) {
        indices.sort((a, b) => colSums[b].compareTo(colSums[a]));
      }
    }

    return HeatmapData(
      rowLabels: rowLabels,
      columnLabels: indices.map((i) => columnLabels[i]).toList(),
      values: values.map((row) => indices.map((i) => row[i]).toList()).toList(),

    );
  }

  /// Преобразует значения в проценты от суммы по строке, столбцу или общей суммы
  ///
  /// Режимы:
  /// - [PercentageMode.none] — без изменений
  /// - [PercentageMode.row] — значения в процентах от суммы по строке
  /// - [PercentageMode.column] — значения в процентах от суммы по столб
  /// - [PercentageMode.total] — значения в процентах от общей суммы
  HeatmapData toPercentages(PercentageMode mode) {
    if (mode == PercentageMode.none) return this;

    final newValues = values.map((row) => row.toList()).toList();

    if (mode == PercentageMode.row) {
      for (int i = 0; i < newValues.length; i++) {
        final rowSum = newValues[i].fold(0.0, (a, b) => a + b);
        if (rowSum == 0) continue;
        for (int j = 0; j < newValues[i].length; j++) {
          newValues[i][j] = newValues[i][j] / rowSum * 100;
        }
      }
    } else if (mode == PercentageMode.column) {
      final cols = newValues.isEmpty ? 0 : newValues[0].length;
      for (int j = 0; j < cols; j++) {
        double colSum = 0;
        for (int i = 0; i < newValues.length; i++) {
          colSum += newValues[i][j];
        }
        if (colSum == 0) continue;
        for (int i = 0; i < newValues.length; i++) {
          newValues[i][j] = newValues[i][j] / colSum * 100;
        }
      }
    } else if (mode == PercentageMode.total) {
      double total = 0;
      for (var row in newValues) {
        total += row.fold(0.0, (a, b) => a + b);
      }
      if (total == 0) return this;
      for (int i = 0; i < newValues.length; i++) {
        for (int j = 0; j < newValues[i].length; j++) {
          newValues[i][j] = newValues[i][j] / total * 100;
        }
      }
    }

    return HeatmapData(
      rowLabels: rowLabels,
      columnLabels: columnLabels,
      values: newValues,

    );
  }

  // асинхронные версии методов для обработки больших матриц в isolate

  /// Асинхронная нормализация данных в isolate для больших матриц
  /// 
  /// Принимает:
  /// - [mode] — режим нормализации (по строкам, столбцам или общая)
  /// Возвращает:
  /// - [Future<HeatmapData>] — новый экземпляр с нормализованными значениями
  Future<HeatmapData> normalizeAsync(NormalizeMode mode) async {
    if (mode == NormalizeMode.none) return this;
    final totalCells = rowLabels.length * columnLabels.length;
    if (totalCells < 50000) return normalize(mode);
    final result = await compute(_normalizeInIsolate, (rowLabels, columnLabels, values, mode.index));
    return HeatmapData(
      rowLabels: result.rowLabels,
      columnLabels: result.columnLabels,
      values: result.values,

    );
  }

  /// Асинхронная сортировка строк в isolate для больших матриц
  /// 
  /// Принимает:
  /// - [mode] — режим сортировки (алфавитный, по возрастанию/убыванию суммы значений)
  /// Возвращает:
  /// - [Future<HeatmapData>] — новый экземпляр с отсортированными строками
  Future<HeatmapData> sortRowsAsync(SortMode mode) async {
    if (mode == SortMode.none) return this;
    final totalCells = rowLabels.length * columnLabels.length;
    if (totalCells < 50000) return sortRows(mode);
    final result = await compute(_sortRowsInIsolate, (rowLabels, columnLabels, values, mode.index));
    return HeatmapData(
      rowLabels: result.rowLabels,
      columnLabels: result.columnLabels,
      values: result.values,

    );
  }

  /// Асинхронная сортировка столбцов в isolate для больших матриц
  /// 
  /// Принимает:
  /// - [mode] — режим сортировки (алфавитный, по возрастанию/убыванию суммы абсолютных значений)
  /// Возвращает:
  /// - [Future<HeatmapData>] — новый экземпляр с отсортированными столбцами
  Future<HeatmapData> sortColsAsync(SortMode mode) async {
    if (mode == SortMode.none) return this;
    final totalCells = rowLabels.length * columnLabels.length;
    if (totalCells < 50000) return sortCols(mode);
    final result = await compute(_sortColsInIsolate, (rowLabels, columnLabels, values, mode.index));
    return HeatmapData(
      rowLabels: result.rowLabels,
      columnLabels: result.columnLabels,
      values: result.values,

    );
  }

  /// Асинхронное преобразование в проценты в isolate для больших матриц
  /// 
  /// Принимает:
  /// - [mode] — режим преобразования в проценты (по строкам, столбцам или общая)
  /// Возвращает:
  /// - [Future<HeatmapData>] — новый экземпляр с преобразованными в проценты значениями
  Future<HeatmapData> toPercentagesAsync(PercentageMode mode) async {
    if (mode == PercentageMode.none) return this;
    final totalCells = rowLabels.length * columnLabels.length;
    if (totalCells < 50000) return toPercentages(mode);
    final result = await compute(_percentagesInIsolate, (rowLabels, columnLabels, values, mode.index));
    return HeatmapData(
      rowLabels: result.rowLabels,
      columnLabels: result.columnLabels,
      values: result.values,

    );
  }

  // Вспомогательные функции для isolate

  /// Результат обработки данных в isolate
  /// Содержит обновленные подписи строк и столбцов, а также новую матрицу значений
  /// Используется для передачи результатов нормализации, сортировки и преобразования в проценты обратно в основной поток
  static _HeatmapDataResult _normalizeInIsolate((List<String> rows, List<String> cols, List<List<double>> vals, int modeIdx) args) {
    final (rows, cols, vals, modeIdx) = args;
    final mode = NormalizeMode.values[modeIdx];
    final newValues = vals.map((row) => row.toList()).toList();
    if (mode == NormalizeMode.row) {
      for (int i = 0; i < newValues.length; i++) {
        double sum = 0;
        for (var v in newValues[i]) {
          sum += v.abs();
        }
        if (sum == 0) continue;
        for (int j = 0; j < newValues[i].length; j++) {
          newValues[i][j] /= sum;
        }
      }
    } else if (mode == NormalizeMode.column) {
      for (int j = 0; j < newValues[0].length; j++) {
        double sum = 0;
        for (var row in newValues) {
          sum += row[j].abs();
        }
        if (sum == 0) continue;
        for (int i = 0; i < newValues.length; i++) {
          newValues[i][j] /= sum;
        }
      }
    } else if (mode == NormalizeMode.total) {
      double total = newValues.expand((e) => e).fold(0.0, (s, v) => s + v.abs());
      if (total != 0) {
        for (int i = 0; i < newValues.length; i++) {
          for (int j = 0; j < newValues[i].length; j++) {
            newValues[i][j] /= total;
          }
        }
      }
    }
    return _HeatmapDataResult(rowLabels: rows, columnLabels: cols, values: newValues);
  }

  /// Асинхронная сортировка строк в isolate для больших матриц
  /// Принимает:
  /// - [mode] — режим сортировки (алфавитный, по возрастанию/убыванию суммы значений)
  /// Возвращает:
  /// - [HeatmapData] — новый экземпляр с отсортированными строками
  static _HeatmapDataResult _sortRowsInIsolate((List<String> rows, List<String> cols, List<List<double>> vals, int modeIdx) args) {
    final (rows, cols, vals, modeIdx) = args;
    final mode = SortMode.values[modeIdx];
    List<int> indices = List.generate(rows.length, (i) => i);
    switch (mode) {
      case SortMode.alphabetic:
        indices.sort((a, b) => rows[a].compareTo(rows[b]));
        break;
      case SortMode.byValueAsc:
        indices.sort((a, b) => vals[a].reduce((x, y) => x + y).compareTo(vals[b].reduce((x, y) => x + y)));
        break;
      case SortMode.byValueDesc:
        indices.sort((a, b) => vals[b].reduce((x, y) => x + y).compareTo(vals[a].reduce((x, y) => x + y)));
        break;
      default:
    }
    return _HeatmapDataResult(
      rowLabels: indices.map((i) => rows[i]).toList(),
      columnLabels: cols,
      values: indices.map((i) => vals[i]).toList(),
    );
  }

  /// Асинхронная сортировка столбцов в isolate для больших матриц
  /// Принимает:
  /// - [mode] — режим сортировки (алфавитный, по возрастанию/убыванию суммы значений)
  /// Возвращает:
  /// - [HeatmapData] — новый экземпляр с отсортированными столбцами
  static _HeatmapDataResult _sortColsInIsolate((List<String> rows, List<String> cols, List<List<double>> vals, int modeIdx) args) {
    final (rows, cols, vals, modeIdx) = args;
    final mode = SortMode.values[modeIdx];
    List<int> indices = List.generate(cols.length, (i) => i);
    if (mode == SortMode.alphabetic) {
      indices.sort((a, b) => cols[a].compareTo(cols[b]));
    } else {
      List<double> colSums = List.generate(cols.length, (j) {
        double s = 0;
        for (var row in vals) {
          s += row[j].abs();
        }
        return s;
      });
      if (mode == SortMode.byValueAsc) {
        indices.sort((a, b) => colSums[a].compareTo(colSums[b]));
      } else if (mode == SortMode.byValueDesc) {
        indices.sort((a, b) => colSums[b].compareTo(colSums[a]));
      }
    }
    return _HeatmapDataResult(
      rowLabels: rows,
      columnLabels: indices.map((i) => cols[i]).toList(),
      values: vals.map((row) => indices.map((i) => row[i]).toList()).toList(),
    );
  }

  /// Асинхронное преобразование в проценты в isolate для больших матриц
  /// Принимает:
  /// - [mode] — режим преобразования в проценты (по строкам, столбцам или общая)
  /// Возвращает:
  /// - [HeatmapData] — новый экземпляр с преобразованными в проценты значениями
  static _HeatmapDataResult _percentagesInIsolate((List<String> rows, List<String> cols, List<List<double>> vals, int modeIdx) args) {
    final (rows, cols, vals, modeIdx) = args;
    final mode = PercentageMode.values[modeIdx];
    final newValues = vals.map((row) => row.toList()).toList();
    if (mode == PercentageMode.row) {
      for (int i = 0; i < newValues.length; i++) {
        final rowSum = newValues[i].fold(0.0, (a, b) => a + b);
        if (rowSum == 0) continue;
        for (int j = 0; j < newValues[i].length; j++) {
          newValues[i][j] = newValues[i][j] / rowSum * 100;
        }
      }
    } else if (mode == PercentageMode.column) {
      final colsCount = newValues.isEmpty ? 0 : newValues[0].length;
      for (int j = 0; j < colsCount; j++) {
        double colSum = 0;
        for (int i = 0; i < newValues.length; i++) {
          colSum += newValues[i][j];
        }
        if (colSum == 0) continue;
        for (int i = 0; i < newValues.length; i++) {
          newValues[i][j] = newValues[i][j] / colSum * 100;
        }
      }
    } else if (mode == PercentageMode.total) {
      double total = 0;
      for (var row in newValues) {
        total += row.fold(0.0, (a, b) => a + b);
      }
      if (total == 0) return _HeatmapDataResult(rowLabels: rows, columnLabels: cols, values: newValues);
      for (int i = 0; i < newValues.length; i++) {
        for (int j = 0; j < newValues[i].length; j++) {
          newValues[i][j] = newValues[i][j] / total * 100;
        }
      }
    }
    return _HeatmapDataResult(rowLabels: rows, columnLabels: cols, values: newValues);
  }
}

/// {@template heatmap_data_result}
/// Вспомогательный класс для возврата результата из isolate
/// {@endtemplate}
class _HeatmapDataResult {
  /// Подписи строк
  final List<String> rowLabels;
  /// Подписи столбцов
  final List<String> columnLabels;
  /// Двумерная матрица значений
  final List<List<double>> values;

  /// {@macro heatmap_data_result}
  _HeatmapDataResult({
    required this.rowLabels, 
    required this.columnLabels, 
    required this.values
  });
}