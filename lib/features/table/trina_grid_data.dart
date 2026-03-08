import 'package:trina_grid/trina_grid.dart';
import '../dataset/dataset.dart';

/// {@template trina_grid_data}
/// Контейнер для данных, подготовленных к отображению в TrinaGrid
/// 
/// Содержит все необходимые компоненты для рендеринга таблицы TrinaGrid:
/// - Колонки с настройками отображения и типами данных
/// - Строки с данными
/// - Группы колонок для визуальной организации
/// {@endtemplate}
class TrinaGridData {
  /// Список колонок для отображения в TrinaGrid
  final List<TrinaColumn> columns;

  /// Список строк для отображения в TrinaGrid
  final List<TrinaRow> rows;

  /// Список групп колонок для отображения в TrinaGrid (опционально)
  /// 
  /// Позволяет визуально группировать связанные колонки по типам данных
  final List<TrinaColumnGroup>? columnGroups;

  /// {@macro trina_grid_data}
  TrinaGridData({
    required this.columns,
    required this.rows,
    this.columnGroups,
  });
}

/// {@template trina_grid_converter}
/// Конвертер для преобразования [Dataset] в формат, совместимый с TrinaGrid
/// 
/// Отвечает за:
/// - Маппинг типов данных из модели в типы TrinaGrid
/// - Формирование структуры колонок с соответствующими настройками
/// - Преобразование строк данных в формат TrinaRow
/// - Создание визуальных групп колонок по типам данных
/// {@endtemplate}
class TrinaGridConverter {
  /// Основной метод конвертации всего датасета
  /// 
  /// Принимает:
  /// - [dataset] — исходный датасет для конвертации
  /// 
  /// Возвращает:
  /// - [TrinaGridData] — данные, готовые для отображения в TrinaGrid
  /// 
  /// Особенности:
  /// - Автоматически определяет типы колонок
  /// - Настраивает возможности сортировки и фильтрации
  /// - Создает группы для визуальной организации
  TrinaGridData convert(Dataset dataset) {
    final columns = _convertColumns(dataset.columns);
    final rows = _convertRows(dataset.columns);
    final columnGroups = _convertColumnGroups(dataset.columns);

    return TrinaGridData(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
    );
  }

  /// Преобразует колонки датасета в формат TrinaColumn
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<TrinaColumn>] — колонки с настройками для TrinaGrid
  /// 
  /// Особенности:
  /// - Для каждой колонки настраивается соответствующий тип данных
  /// - Включаются возможности сортировки и фильтрации
  /// - Редактирование отключено (только просмотр)
  List<TrinaColumn> _convertColumns(List<DataColumn> columns) {
    return columns.map((column) {
      final type = _mapColumnType(column);

      return TrinaColumn(
        title: column.name,
        field: column.name,
        type: type,
        enableEditingMode: false,
        enableSorting: true,
        enableFilterMenuItem: true,
        enableColumnDrag: true,
      );
    }).toList();
  }

  /// Вспомогательный метод для определения типов колонок TrinaGrid
  /// 
  /// Принимает:
  /// - [column] — колонка датасета
  /// 
  /// Возвращает:
  /// - [TrinaColumnType] — соответствующий тип для TrinaGrid
  /// 
  /// Особенности:
  /// - [NumericColumn] → число с форматированием
  /// - [DateTimeColumn] → дата
  /// - [CategoricalColumn] → выпадающий список
  /// - Остальные → текст
  TrinaColumnType _mapColumnType(DataColumn column) {
    if (column is NumericColumn) {
      return TrinaColumnType.number(format: '#,###.##');
    }

    if (column is DateTimeColumn) {
      return TrinaColumnType.date(format: 'yyyy-MM-dd');
    }

    if (column is CategoricalColumn) {
      return TrinaColumnType.select(_getUniqueValues(column));
    }

    return TrinaColumnType.text();
  }

  /// Получение уникальных значений для категориальной колонки
  /// 
  /// Принимает:
  /// - [column] — категориальная колонка
  /// 
  /// Возвращает:
  /// - [List<String>] — отсортированный список уникальных значений
  List<String> _getUniqueValues(CategoricalColumn column) {
    return column.data
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  /// Преобразует строки датасета в формат TrinaRow
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<TrinaRow>] — строки данных для TrinaGrid
  /// 
  /// Особенности:
  /// - Количество строк определяется по первой колонке
  /// - Для каждой ячейки создается TrinaCell с соответствующим значением
  List<TrinaRow> _convertRows(List<DataColumn> columns) {
    final rowCount = columns.first.length;
    final rows = <TrinaRow>[];

    for (int i = 0; i < rowCount; i++) {
      final cells = <String, TrinaCell>{};

      for (final column in columns) {
        cells[column.name] = TrinaCell(
          value: column[i],
        );
      }

      rows.add(TrinaRow(cells: cells));
    }

    return rows;
  }

  /// Создает группы колонок для визуальной организации
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<TrinaColumnGroup>] — группы колонок по типам данных
  /// 
  /// Группирует колонки по их типу данных:
  /// - Числовые (Numeric)
  /// - Дата/время (Date)
  /// - Текстовые (Text)
  /// - Категориальные (Categorical)
  /// 
  /// Это улучшает навигацию по таблице с большим количеством колонок
  List<TrinaColumnGroup> _convertColumnGroups(List<DataColumn> columns) {
    final groups = <TrinaColumnGroup>[];

    final numeric = columns.whereType<NumericColumn>();
    final dates = columns.whereType<DateTimeColumn>();
    final text = columns.whereType<TextColumn>();
    final categorical = columns.whereType<CategoricalColumn>();

    if (numeric.isNotEmpty) {
      groups.add(
        TrinaColumnGroup(
          title: 'Numeric',
          fields: numeric.map((c) => c.name).toList(),
        ),
      );
    }

    if (dates.isNotEmpty) {
      groups.add(
        TrinaColumnGroup(
          title: 'Date',
          fields: dates.map((c) => c.name).toList(),
        ),
      );
    }

    if (text.isNotEmpty) {
      groups.add(
        TrinaColumnGroup(
          title: 'Text',
          fields: text.map((c) => c.name).toList(),
        ),
      );
    }

    if (categorical.isNotEmpty) {
      groups.add(
        TrinaColumnGroup(
          title: 'Categorical',
          fields: categorical.map((c) => c.name).toList(),
        ),
      );
    }

    return groups;
  }
}