import 'dart:math';

import '../../dataset/dataset.dart';

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

  ///{@macro correlation_matrix}
  CorrelationMatrix(this.fieldNames, this.values) : _indexMap = {
    for (int i = 0; i < fieldNames.length; i++) fieldNames[i]: i
  };
  
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
  factory CorrelationMatrix.fromColumns(List<DataColumn> columns) {
    // Отбираем числовые колонки
    final numColumns = columns.where((c) => c.type == ColumnType.numeric).toList();
    
    if (numColumns.length < 2) {
      return CorrelationMatrix([], []);
    }
    
    final fieldNames = numColumns.map((c) => c.name!).toList();
    final n = fieldNames.length;
    
    // Инициализируем матрицу нулями
    final values = List.generate(n, (_) => List.filled(n, 0.0));
    
    // Заполняем диагональ единицами и считаем корреляции
    for (int i = 0; i < n; i++) {
      values[i][i] = 1.0; // Корреляция с собой
      
      for (int j = i + 1; j < n; j++) {
        final corr = _calculatePearsonCorrelation(
          numColumns[i].values.cast<num>(),
          numColumns[j].values.cast<num>(),
        );
        
        // Симметричная матрица
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
    final i = fieldNames.indexOf(f1);
    final j = fieldNames.indexOf(f2);
    return values[i][j];
  }
  /// Получить корреляцию по индексам (быстро)
  double getByIndex(int i, int j) {
    return values[i][j];
  }
  
  /// Размер матрицы
  int get size => fieldNames.length;
  
  /// Пустая ли матрица
  bool get isEmpty => fieldNames.isEmpty;
  
  /// Проверить наличие поля
  bool contains(String fieldName) => _indexMap.containsKey(fieldName);
  
  /// Получить список значений для строки i
  List<double> row(int i) => List.unmodifiable(values[i]);
  
  /// Получить список значений для столбца j
  List<double> column(int j) => List.unmodifiable(
    List.generate(size, (i) => values[i][j])
  );
  
  
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