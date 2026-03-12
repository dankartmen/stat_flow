
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
  late final List<List<double>> _transposed;

  /// {@macro correlation_matrix}
  CorrelationMatrix(
    List<String> fieldNames,
    List<List<double>> values,
  ) : fieldNames = List.unmodifiable(fieldNames),
    // Явно указываем тип
    values = List<List<double>>.unmodifiable(
      values.map(
        (row) => List<double>.unmodifiable(row),
      ),
    ),

    _indexMap = {
      for (int i = 0; i < fieldNames.length; i++)
        fieldNames[i]: i
    },

    _transposed = List.generate(
      values.length,
      (col) => List<double>.generate(
        values.length,
        (row) => values[row][col],
      ),
    );
  
  /// Фабричный конструктор, позволяющий 
  /// 
  /// Принимает:
  /// - [dataset] — датасет, из которого будет построена матрица корреляции.
  /// 
  /// Возвращает:
  /// - [Map<String, Map<String, double>>] — матрицу корреляции, где ключи внешнего 
  ///   Map — названия полей, а внутреннего — названия полей для корреляции.
  /// 
  /// Если данные пусты или колонок меньше 2-х, создаёт экземпляр класса с пустыми переменными.
  factory CorrelationMatrix.fromDataset(Dataset dataset) {
    final numericColumns = dataset.numericColumns;

    if (numericColumns.length < 2) {
      return CorrelationMatrix([], []);
    }

    final names = numericColumns.map((c) => c.name).toList();

    final n = numericColumns.length;

    final values = List.generate(
      n,
      (_) => List.filled(n, 0.0),
    );

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

  /// Метод для получения значения матрицы по названию двух полей
  /// Принимает:
  /// - [f1] и [f2] — имена полей матрицы
  /// 
  /// Возвращает:
  /// - Число в матрице
  double get(String f1, String f2) {
    final i = _indexMap[f1]!;
    final j = _indexMap[f2]!;
    return values[i][j];
  }
  /// Получить корреляцию по индексам
  double getByIndex(int i, int j) => values[i][j];
  
  /// Размер матрицы
  int get size => fieldNames.length;
  
  /// Пустая ли матрица
  bool get isEmpty => fieldNames.isEmpty;
  
  /// Проверить наличие поля
  bool contains(String fieldName) => _indexMap.containsKey(fieldName);
  
  /// Получить список значений для строки i
  List<double> row(int i) => values[i];
  
  /// Получить список значений для столбца j
  List<double> column(int j) => _transposed[j];
}