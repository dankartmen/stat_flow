import 'package:pluto_grid/pluto_grid.dart';
import '../dataset/dataset.dart';

/// {@template pluto_grid_data}
/// Вспомогательный класс для возврата данных, подготовленных для отображения в PlutoGrid
/// {@endtemplate}
class PlutoGridData {
  /// Список колонок для отображения в PlutoGrid
  final List<PlutoColumn> columns;

  /// Список строк для отображения в PlutoGrid
  final List<PlutoRow> rows;

  /// Список групп колонок для отображения в PlutoGrid(опционально)
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
/// Класс для конвертации данных для [PlutoGrid] из [Dataset] 
/// {@endtemplate}
class PlutoGridConverter {

  /// Основной метод конвертации всего датасета
  /// 
  /// Принимает [Dataset] и возвращает [PlutoGridData], готовый для отображения в таблице
  PlutoGridData convert(Dataset dataset){
    final columns = convertColumns(dataset.columns);
    final rows = convertRows(dataset.columns);
    final columnGroups = convertColumnGroups(dataset.columns);
    return PlutoGridData(columns: columns, rows: rows, columnGroups: columnGroups);
  }

  /// Преобразует колонки датасета в формат PlutoGrid
  List<PlutoColumn> convertColumns(List<DataColumn> columns) {
    return columns.map((column) {
       // Определяем заголовок: либо имя колонки, либо "Колонка N"
      final String title = column.name ?? 'Колонка ${columns.indexOf(column) + 1}';

      // Определяем поле для привязки данных
      final String field = column.name ?? 'column_${columns.indexOf(column)}';
      
      // Определяем тип колонки 
      final PlutoColumnType type = _mapColumnType(column);
      
      return PlutoColumn(
        title: title,
        field: field,
        type: type,
        enableEditingMode: false,   // Запрещаем редактирование
        enableSorting: true,        // Разрешаем сортировку
        enableFilterMenuItem: true, // Разрешаем фильтрацию

      );
    }).toList();
  }

  /// Вспомогательный метод для определения типов
   PlutoColumnType _mapColumnType(DataColumn column) {
    switch (column.type) {
      case ColumnType.numeric:
        return PlutoColumnType.number(
          // Форматирование для чисел
          format: '#,###.##',
        );
        
      case ColumnType.datetime:
        return PlutoColumnType.date(
          // Указываем формат даты
          format: 'yyyy-MM-dd',
        );
        
      case ColumnType.categorical:
        // Для категориальных данных используем select с уникальными значениями
        final uniqueValues = _getUniqueValues(column);
        return PlutoColumnType.select(uniqueValues);
        
      case ColumnType.text:
        return PlutoColumnType.text();
        
      default:
        return PlutoColumnType.text();
    }
  }

  /// Получение уникальных значений для категориальной колонки
   List<String> _getUniqueValues(DataColumn column) {
    return column.values
        .where((value) => value != null)
        .map((value) => value.toString())
        .toSet()
        .toList()
        ..sort(); 
  }

  /// Преобразует данные в строки PlutoGrid
  List<PlutoRow> convertRows(List<DataColumn> columns){
    final rows = <PlutoRow>[];
    for (var i = 0; i < columns.first.values.length; i++) {
      final cells = <String, PlutoCell>{};
      for (var column in columns) {
        final cellValue = column.values[i];
        cells[column.name ?? column.values.first.toString()] = PlutoCell(value: cellValue);
      }
      rows.add(PlutoRow(cells: cells));
    }
    return rows;
  }

  /// Создает группы колонок для визуальной организации
  /// 
  /// Группирует колонки по их типу данных:
  /// - Числовые
  /// - Дата/время
  /// - Текстовые
  /// - Категориальные
  /// 
  /// Это улучшает навигацию по таблице с большим количеством колонок
  List<PlutoColumnGroup> convertColumnGroups(List<DataColumn> columns){
    /// Группируем колонки по типу данных
    final groups = <PlutoColumnGroup>[];
    final numericColumns = columns.where((col) => col.type == ColumnType.numeric).toList();
    final datetimeColumns = columns.where((col) => col.type == ColumnType.datetime).toList();
    final textColumns = columns.where((col) => col.type == ColumnType.text).toList();
    final categoricalColumns = columns.where((col) => col.type == ColumnType.categorical).toList();

    if (numericColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(title: 'Числовые', fields: numericColumns.map((col) => col.name ?? col.values.first.toString()).toList()));
    }
    if (datetimeColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(title: 'Дата/Время', fields: datetimeColumns.map((col) => col.name ?? col.values.first.toString()).toList()));
    }
    if (textColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(title: 'Текстовые', fields: textColumns.map((col) => col.name ?? col.values.first.toString()).toList()));
    }
    if (categoricalColumns.isNotEmpty) {
      groups.add(PlutoColumnGroup(title: 'Категориальные', fields: categoricalColumns.map((col) => col.name ?? col.values.first.toString()).toList()));
    }

    return groups;
  }
}