import 'dart:math';

import '../../../dataset/dataset.dart';

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

  ///{@macro correlation_matrix}
  CorrelationMatrix(
    List<String> fieldNames,
    List<List<double>> values,
  ) : fieldNames = List.unmodifiable(fieldNames),
    // 👇 Явно указываем тип
    values = List<List<double>>.unmodifiable(
      values.map(
        (row) => List<double>.unmodifiable(row),
      ),
    ),

    // 👇 Инициализируем final поля в initializer list
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
  /// - [columns] — список колонок с данными для анализа,
  /// 
  /// Возвращает:
  /// - [Map<String, Map<String, double>>] — матрицу корреляции, где ключи внешнего 
  ///   Map — названия полей, а внутреннего — названия полей для корреляции.
  /// 
  /// Если данные пусты или колонок меньше 2-х, создаёт экземпляр класса с пустыми переменными.
  factory CorrelationMatrix.fromColumns(
    List<DataColumn> columns,
  ) {
    final numericColumns = columns
        .where((c) => c.type == ColumnType.numeric)
        .toList();

    if (numericColumns.length < 2) {
      return CorrelationMatrix([], []);
    }

    //  Проверяем имена
    final fieldNames = numericColumns.map((c) {
      if (c.name == null) {
        throw ArgumentError(
          'У числового столбца должно быть название',
        );
      }
      return c.name!;
    }).toList();

    // Преобразуем значения в double
    final data = numericColumns.map((col) {
      return col.values.map((v) {
        if (v == null) {
          throw ArgumentError(
            'В числовом столбце обнаружено пустое значение ${col.name}',
          );
        }

        if (v is num) {
          return v.toDouble();
        }

        throw ArgumentError(
          'Недопустимое значение в столбце ${col.name}',
        );
      }).toList();
    }).toList();

    // 4️⃣ Проверяем одинаковую длину
    final length = data.first.length;

    for (final col in data) {
      if (col.length != length) {
        throw ArgumentError(
          'Все числовые столбцы должны иметь одинаковую длину',
        );
      }
    }

    final n = fieldNames.length;

    // 5️⃣ Создаём матрицу
    final values = List.generate(
      n,
      (_) => List.filled(n, 0.0),
    );

    for (int i = 0; i < n; i++) {
      values[i][i] = 1.0;

      for (int j = i + 1; j < n; j++) {
        final corr = _calculatePearsonCorrelation(data[i], data[j]);

        values[i][j] = corr;
        values[j][i] = corr;
      }
    }

    return CorrelationMatrix(fieldNames, values);
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
  /// Получить корреляцию по индексам (быстро)
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
  
  /// Расчет корреляции Пирсона
  static double _calculatePearsonCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length) return 0.0;
    
    final n = x.length;
    if (n == 0) return 0.0;
    
    double sumX = 0.0, sumY = 0.0, sumXY = 0.0;
    double sumX2 = 0.0, sumY2 = 0.0;
    
    for (int i = 0; i < n; i++) {
      sumX += x[i].toDouble();
      sumY += y[i].toDouble();
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }
    
    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }

  
}