import '../charts/heatmap/calculator/heatmap_calculator.dart';
import '../charts/heatmap/model/correlation_matrix.dart';
import 'dataset.dart';

/// {@template correlation_matrix_builder}
/// Строитель для создания матрицы корреляции из числовых колонок датасета
/// 
/// Предоставляет статические методы для конструирования [CorrelationMatrix]
/// на основе переданных числовых данных. Инкапсулирует логику попарного
/// вычисления корреляции между всеми колонками.
/// {@endtemplate}
class CorrelationMatrixBuilder {
  /// Создает матрицу корреляции из списка числовых колонок
  /// 
  /// Принимает:
  /// - [columns] — список числовых колонок [NumericColumn] для анализа
  /// 
  /// Возвращает:
  /// - [CorrelationMatrix] — заполненную матрицу корреляции
  /// 
  /// Особенности:
  /// - На диагонали матрицы всегда стоит 1 (корреляция колонки с собой)
  /// - Матрица симметрична относительно главной диагонали
  /// - Для каждой пары колонок вычисляется корреляция Пирсона
  static CorrelationMatrix fromNumericColumns(
    List<NumericColumn> columns,
  ) {
    final names = columns.map((c) => c.name).toList();
    final n = columns.length;

    final matrix = List.generate(
      n,
      (_) => List.filled(n, 0.0),
    );

    for (int i = 0; i < n; i++) {
      matrix[i][i] = 1;

      for (int j = i + 1; j < n; j++) {
        final corr = HeatmapCalculator.calculatePearsonCorrelation(
          columns[i].data,
          columns[j].data,
        );

        matrix[i][j] = corr;
        matrix[j][i] = corr;
      }
    }

    return CorrelationMatrix(
      names,
      matrix,
    );
  }
}