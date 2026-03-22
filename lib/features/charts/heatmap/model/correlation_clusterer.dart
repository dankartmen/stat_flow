import 'package:stat_flow/features/charts/heatmap/model/heatmap_data.dart';

import 'correlation_matrix.dart';

/// {@template correlation_clusterer}
/// Класс для кластеризации (переупорядочивания) матрицы корреляции
/// на основе сумм абсолютных значений коэффициентов.
/// {@endtemplate}
class CorrelationClusterer {
  /// {@macro correlation_clusterer}
  /// 
  /// Принимает:
  /// - [matrix] — исходная матрица корреляции
  /// 
  /// Возвращает:
  /// - [CorrelationMatrix] — переупорядоченную матрицу, где поля с наибольшими
  ///   суммами абсолютных корреляций располагаются в начале
  static CorrelationMatrix cluster(CorrelationMatrix matrix) {
    final size = matrix.size;
    final indices = List.generate(size, (i) => i);

    // Предварительно рассчитываем суммы абсолютных значений для каждой строки
    final sums = List.generate(size, (row) {
      double s = 0;
      for (int col = 0; col < size; col++) {
        s += matrix.getByIndex(row, col).abs();
      }
      return s;
    });

    // Сортируем индексы по убыванию сумм
    indices.sort((a, b) => sums[b].compareTo(sums[a]));

    // Перестраиваем матрицу в соответствии с новым порядком индексов
    return CorrelationMatrix(
      indices.map((i) => matrix.fieldNames[i]).toList(),
      List.generate(size, (i) {
        final row = indices[i];
        return List.generate(size, (j) => matrix.getByIndex(row, indices[j]));
      }),
    );
  }


  /// Альтернативный метод, который принимает [HeatmapData] и возвращает новый экземпляр
  /// с переупорядоченными строками и столбцами на основе суммы абсолютных
  static HeatmapData clusterHeatmapData(HeatmapData data) {
    final size = data.columnLabels.length;
    final indices = List.generate(size, (i) => i);

    // Предварительно рассчитываем суммы абсолютных значений для каждой строки
    final sums = List.generate(size, (row) {
      double s = 0;
      for (int col = 0; col < size; col++) {
        s += data.values[row][col].abs();
      }
      return s;
    });

    // Сортируем индексы по убыванию сумм
    indices.sort((a, b) => sums[b].compareTo(sums[a]));

    // Перестраиваем данные в соответствии с новым порядком индексов
    return HeatmapData(
      rowLabels: indices.map((i) => data.rowLabels[i]).toList(),
      columnLabels: indices.map((i) => data.columnLabels[i]).toList(),
      values: List.generate(size, (i) {
        final row = indices[i];
        return List.generate(size, (j) => data.values[row][indices[j]]);
      }),
    );
  }
}