import 'package:stat_flow/features/charts/heatmap/model/heatmap_state.dart';

import 'correlation_matrix.dart';

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
  /// Подписи строк (обычно названия признаков или категорий)
  final List<String> rowLabels;
  
  /// Подписи столбцов
  final List<String> columnLabels;
  
  /// Двумерная матрица значений для отображения
  final List<List<double>> values;

  /// Минимальное значение в матрице (используется для цветовой шкалы)
  late final double min;
  
  /// Максимальное значение в матрице (используется для цветовой шкалы)
  late final double max;

  /// {@macro heatmap_data}
  HeatmapData({
    required this.rowLabels,
    required this.columnLabels,
    required this.values,
  }) {
    final all = values.expand((v) => v).toList();
    min = all.isEmpty ? 0 : all.reduce((a, b) => a < b ? a : b);
    max = all.isEmpty ? 1 : all.reduce((a, b) => a > b ? a : b);
  }

  /// Создает экземпляр [HeatmapData] из корреляционной матрицы
  /// 
  /// Особенности:
  /// - Использует те же имена полей для строк и столбцов (симметричная матрица)
  /// - Подходит для визуализации корреляций между признаками
  /// - Значения находятся в диапазоне [-1, 1]
  /// 
  /// Принимает:
  /// - [matrix] — корреляционная матрица, полученная из датасета
  /// 
  /// Возвращает:
  /// - [HeatmapData] — данные для отображения тепловой карты корреляций
  factory HeatmapData.fromCorrelation(CorrelationMatrix matrix) {
    return HeatmapData(
      rowLabels: matrix.fieldNames,
      columnLabels: matrix.fieldNames,
      values: matrix.values,
    );
  }

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

    final newValues = values.map((row) => row.toList()).toList(); // глубокая копия

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
    List<int> indices = List.generate(rowLabels.length, (i) => i);
    switch (mode) {
      case SortMode.none:
        return this;
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
}