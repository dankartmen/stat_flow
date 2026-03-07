import 'package:pluto_grid/pluto_grid.dart';
import '../dataset/dataset.dart';

/// {@template pluto_grid_data}
/// Контейнер для данных, подготовленных к отображению в таблице PlutoGrid
/// 
/// Содержит все необходимые компоненты для рендеринга таблицы:
/// - Колонки с настройками отображения
/// - Строки с данными
/// - Группы колонок для визуальной организации
/// {@endtemplate}
class PlutoGridData {
  /// Список колонок для отображения в PlutoGrid
  final List<PlutoColumn> columns;

  /// Список строк для отображения в PlutoGrid
  final List<PlutoRow> rows;

  /// Список групп колонок для отображения в PlutoGrid (опционально)
  /// 
  /// Позволяет визуально группировать связанные колонки (например, все числовые колонки вместе)
  final List<PlutoColumnGroup>? columnGroups;
  
  /// {@macro pluto_grid_data}
  PlutoGridData({
    required this.columns,
    required this.rows,
    this.columnGroups,
  });
}

/// {@template pluto_grid_converter}
/// Конвертер для преобразования [Dataset] в формат, совместимый с таблицей PlutoGrid
/// 
/// Отвечает за:
/// - Маппинг типов данных из модели в типы PlutoGrid
/// - Формирование структуры колонок с соответствующими настройками
/// - Преобразование строк данных в формат PlutoRow
/// - Создание визуальных групп колонок по типам данных
/// {@endtemplate}
class PlutoGridConverter {
  /// Основной метод конвертации всего датасета
  /// 
  /// Принимает:
  /// - [dataset] — исходный датасет для конвертации
  /// 
  /// Возвращает:
  /// - [PlutoGridData] — данные, готовые для отображения в таблице
  /// 
  /// Особенности:
  /// - Автоматически определяет типы колонок
  /// - Настраивает возможности сортировки и фильтрации
  /// - Создает группы для визуальной организации
  PlutoGridData convert(Dataset dataset){
    final columns = _convertColumns(dataset.columns);
    final rows = _convertRows(dataset.columns);
    final columnGroups = _convertColumnGroups(dataset.columns);
    return PlutoGridData(columns: columns, rows: rows, columnGroups: columnGroups);
  }

  /// Преобразует колонки датасета в формат PlutoGrid
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<PlutoColumn>] — колонки с настройками для PlutoGrid
  /// 
  /// Особенности:
  /// - Для каждой колонки настраивается соответствующий тип данных
  /// - Включаются возможности сортировки и фильтрации
  /// - Редактирование отключено (только просмотр)
  List<PlutoColumn> _convertColumns(List<DataColumn> columns) {
    return columns.map((column) {
      final title = column.name;
      final field = column.name;
      final type = _mapColumnType(column);

      return PlutoColumn(
        title: title,
        field: field,
        type: type,
        enableEditingMode: false,
        enableSorting: true,
        enableFilterMenuItem: true,
        enableAutoEditing: true,
        enableColumnDrag: true,
        enableContextMenu: true,
        enableHideColumnMenuItem: true,
      );
    }).toList();
  }

  /// Вспомогательный метод для определения типов колонок PlutoGrid
  /// 
  /// Принимает:
  /// - [column] — колонка датасета
  /// 
  /// Возвращает:
  /// - [PlutoColumnType] — соответствующий тип для PlutoGrid
  /// 
  /// Особенности:
  /// - [NumericColumn] → число с форматированием
  /// - [DateTimeColumn] → дата
  /// - [CategoricalColumn] → выпадающий список
  /// - Остальные → текст
  PlutoColumnType _mapColumnType(DataColumn column) {
    if (column is NumericColumn) {
      return PlutoColumnType.number(format: '#,###.##');
    }

    if (column is DateTimeColumn) {
      return PlutoColumnType.date(format: 'yyyy-MM-dd');
    }

    if (column is CategoricalColumn) {
      return PlutoColumnType.select(_getUniqueValues(column));
    }

    return PlutoColumnType.text();
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

  /// Преобразует строки датасета в формат PlutoRow
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<PlutoRow>] — строки данных для PlutoGrid
  /// 
  /// Особенности:
  /// - Количество строк определяется по первой колонке
  /// - Для каждой ячейки создается PlutoCell с соответствующим значением
  List<PlutoRow> _convertRows(List<DataColumn> columns) {
    final rowCount = columns.first.length;
    final rows = <PlutoRow>[];

    for (int i = 0; i < rowCount; i++) {
      final cells = <String, PlutoCell>{};

      for (final column in columns) {
        cells[column.name] = PlutoCell(
          value: column[i],
        );
      }

      rows.add(PlutoRow(cells: cells));
    }

    return rows;
  }

  /// Создает группы колонок для визуальной организации
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<PlutoColumnGroup>] — группы колонок по типам данных
  /// 
  /// Группирует колонки по их типу данных:
  /// - Числовые
  /// - Дата/время
  /// - Текстовые
  /// - Категориальные
  /// 
  /// Это улучшает навигацию по таблице с большим количеством колонок
  List<PlutoColumnGroup> _convertColumnGroups(List<DataColumn> columns){
    final groups = <PlutoColumnGroup>[];
    final numericColumns = columns.whereType<NumericColumn>().toList();
    final dateTimeColumns = columns.whereType<DateTimeColumn>().toList();
    final textColumns = columns.whereType<TextColumn>().toList();
    final categoricalColumns = columns.whereType<CategoricalColumn>().toList();

    if (numericColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(
        title: 'Числовые', 
        fields: numericColumns.map((col) => col.name).toList()
      ));
    }
    if (dateTimeColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(
        title: 'Дата/Время', 
        fields: dateTimeColumns.map((col) => col.name).toList()
      ));
    }
    if (textColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(
        title: 'Текстовые', 
        fields: textColumns.map((col) => col.name).toList()
      ));
    }
    if (categoricalColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(
        title: 'Категориальные', 
        fields: categoricalColumns.map((col) => col.name).toList()
      ));
    }

    return groups;
  }
}