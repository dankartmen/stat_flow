/// {@template dataset}
/// Класс, хранящий название набора данных и список колонок
/// {@endtemplate}
class Dataset {
  /// Название набора данных
  final String name;

  /// Список колонок с данными
  final List<DataColumn> columns;

  /// {@macro dataset}
  Dataset ({
    required this.name,
    required this.columns
  });
}

/// {@template column_type}
/// Перечисление типов данных, которые могут содержаться в колонке
/// {@endtemplate}
enum ColumnType {
  /// Числовой тип (возраст, зарплата, кол-во чего-нибудь) 
  numeric,

  /// Категориальный тип (пол, регион)
  categorical,

  /// Временной тип (временная метка, дата замера)
  datetime,

  /// Текстовой тип (описание, комментарий)
  text 
}

///{@template data_column}
/// Класс, хранящий название колонки, его тип и массив значений
///{@endtemplate}
class DataColumn {
  /// Название колонки
  final String? name;
  /// Тип колонки
  final ColumnType type;
  /// Список с значениями
  final List<dynamic> values;

  DataColumn({
    this.name,
    required this.type,
    required this.values,
  });

  /// Фабричный конструктор для создания колонки с автоматически сгенерированным названием
  /// 
  /// Используется, когда исходные данные не содержат заголовков (например, CSV без первой строки-шапки).
  /// Название формируется по шаблону "Колонка {index}", где index — порядковый номер колонки.
  /// 
  /// - [index] - порядковый номер колонки (начиная с 0 или 1, в зависимости от контекста)
  /// - [type] - тип данных в колонке
  /// - [values] - массив значений
  factory DataColumn.withDefaultName({
    required int index,
    required ColumnType type,
    required List<dynamic> values,
  }) {
    return DataColumn(
      name: 'Колонка $index',
      type: type,
      values: values,
    );
  }
}