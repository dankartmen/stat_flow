import '../../features/statistics/statistic_result.dart';
import '../../features/statistics/statistic_calculator.dart';

part 'dataset_extensions.dart';

/// {@template dataset}
/// Основной контейнер для данных, загруженных из CSV-файла
/// 
/// Содержит:
/// - Название датасета (имя файла)
/// - Список колонок различных типов ([DataColumn])
/// - Карту для быстрого доступа к колонкам по имени
/// 
/// Предоставляет базовые операции:
/// - Получение количества строк и колонок
/// - Доступ к колонке по имени
/// - Дополнительные операции через extension-методы
/// {@endtemplate}
class Dataset {
  /// Название датасета (обычно имя файла)
  final String name;

  /// Список всех колонок датасета
  final List<DataColumn> columns;

  /// Карта для быстрого доступа к колонкам по имени
  final Map<String, DataColumn> _columnMap;

  /// {@macro dataset}
  Dataset({
    required this.name,
    required this.columns,
  }) : _columnMap = {
      for(final c in columns) c.name: c
  };

  /// Количество строк в датасете (определяется по первой колонке)
  int get rowCount => columns.isEmpty ? 0 : columns.first.length;

  /// Количество колонок в датасете
  int get columnCount => columns.length;

  /// Возвращает колонку по имени или null, если колонка не найдена
  DataColumn? column(String name) => _columnMap[name];
}

/// {@template data_column}
/// Абстрактный базовый класс для колонки данных определенного типа
/// 
/// Предоставляет общую функциональность:
/// - Хранение имени колонки
/// - Хранение списка значений (с поддержкой null)
/// - Доступ по индексу через оператор []
/// - Операции фильтрации и среза данных
/// 
/// Типизированные наследники:
/// - [NumericColumn] - числовые значения
/// - [TextColumn] - текстовые значения
/// - [DateTimeColumn] - значения даты/времени
/// - [CategoricalColumn] - категориальные значения с кодированием
/// {@endtemplate}
abstract class DataColumn<T> {
  /// Имя колонки
  final String name;

  /// Список значений колонки (может содержать null)
  final List<T?> data;

  /// {@macro data_column}
  const DataColumn(this.name, this.data);

  /// Количество значений в колонке
  int get length => data.length;

  /// Оператор доступа по индексу
  T? operator [](int i) => data[i];

  /// Создает копию колонки с новыми данными
  DataColumn<T> copyWithData(List<T?> newData);

  /// Возвращает срез колонки от start до end (не включая end)
  DataColumn<T> slice(int start, int end) {
    return copyWithData(data.sublist(start, end));
  }

  /// Фильтрует колонку по индексам
  DataColumn<T> filterByIndices(List<int> indices) {
    final result = <T?>[];

    for (final i in indices) {
      result.add(data[i]);
    }

    return copyWithData(result);
  }

  /// Фильтрует колонку по предикату, применяемому к индексам
  DataColumn<T> filter(bool Function(int index) predicate) {
    final result = <T?>[];

    for (int i = 0; i < data.length; i++) {
      if (predicate(i)) {
        result.add(data[i]);
      }
    }

    return copyWithData(result);
  }
}

/// {@template numeric_column}
/// Числовая колонка, содержащая значения типа double
/// {@endtemplate}
class NumericColumn extends DataColumn<double> {
  /// {@macro numeric_column}
  const NumericColumn(super.name, super.data);

  @override
  NumericColumn copyWithData(List<double?> newData) {
    return NumericColumn(name, newData);
  }
}

/// {@template text_column}
/// Текстовая колонка, содержащая строковые значения
/// {@endtemplate}
class TextColumn extends DataColumn<String> {
  /// {@macro text_column}
  const TextColumn(super.name, super.data);

  @override
  TextColumn copyWithData(List<String?> newData) {
    return TextColumn(name, newData);
  }
}

/// {@template date_time_column}
/// Колонка даты/времени, содержащая значения DateTime
/// {@endtemplate}
class DateTimeColumn extends DataColumn<DateTime> {
  /// {@macro date_time_column}
  const DateTimeColumn(super.name, super.data);

  @override
  DateTimeColumn copyWithData(List<DateTime?> newData) {
    return DateTimeColumn(name, newData);
  }
}

/// {@template categorical_column}
/// Категориальная колонка с автоматическим кодированием уникальных значений
/// 
/// Особенности:
/// - Хранит строковые значения
/// - Автоматически создает числовые коды для каждой уникальной категории
/// - Предоставляет доступ к закодированным значениям через поле [encoded]
/// {@endtemplate}
class CategoricalColumn extends DataColumn<String> {
  /// Карта соответствия "категория -> код"
  late final Map<String, int> _codes;

  /// Закодированные числовые значения категорий
  late final List<int?> encoded;

  /// {@macro categorical_column}
  CategoricalColumn(String name, List<String?> data)
      : super(name, data) {
    final map = <String, int>{};
    int index = 0;

    encoded = data.map((v) {
      if (v == null) return null;
      return map.putIfAbsent(v, () => index++);
    }).toList();

    _codes = map;
  }

  @override
  CategoricalColumn copyWithData(List<String?> newData) {
    return CategoricalColumn(name, newData);
  }
}

/// {@template dataset_row}
/// Представление одной строки датасета с доступом к значениям по имени колонки
/// 
/// Позволяет удобно получать значения из разных колонок одной строки:
/// ```dart
/// final row = DatasetRow(dataset, 5);
/// final age = row['age'];
/// final name = row['name'];
/// ```
/// {@endtemplate}
class DatasetRow {
  /// Датасет, к которому относится строка
  final Dataset dataset;

  /// Индекс строки в датасете
  final int index;

  /// {@macro dataset_row}
  DatasetRow(this.dataset, this.index);

  /// Оператор доступа к значению колонки по имени
  /// 
  /// Выбрасывает исключение, если колонка не найдена
  dynamic operator [](String columnName) {
    final column = dataset.column(columnName);

    if (column == null) {
      throw Exception("Колонка '$columnName' не найдена");
    }

    return column[index];
  }
}