import 'package:flutter/material.dart' hide DataColumn;
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../core/dataset/dataset.dart';
import 'dataset_datasource.dart';

/// {@template syncfusion_grid_data}
/// Контейнер для данных, подготовленных к отображению в Syncfusion DataGrid
/// 
/// Содержит все необходимые компоненты для рендеринга таблицы Syncfusion:
/// - Колонки с настройками отображения
/// - Источник данных с преобразованными строками
/// {@endtemplate}
class SyncfusionGridData {
  /// Список колонок для отображения в Syncfusion DataGrid
  final List<GridColumn> columns;

  /// Источник данных для Syncfusion DataGrid
  final DatasetDataSource source;

  /// {@macro syncfusion_grid_data}
  SyncfusionGridData({
    required this.columns,
    required this.source,
  });
}

/// {@template syncfusion_grid_converter}
/// Конвертер для преобразования [Dataset] в формат, совместимый с Syncfusion DataGrid
/// 
/// Отвечает за:
/// - Создание колонок GridColumn из колонок датасета
/// - Инициализацию источника данных [DatasetDataSource]
/// - Формирование структуры для отображения в Syncfusion DataGrid
/// {@endtemplate}
class SyncfusionGridConverter {
  /// Основной метод конвертации всего датасета
  /// 
  /// Принимает:
  /// - [dataset] — исходный датасет для конвертации
  /// 
  /// Возвращает:
  /// - [SyncfusionGridData] — данные, готовые для отображения в Syncfusion DataGrid
  /// 
  /// Особенности:
  /// - Создает колонки с базовым форматированием
  /// - Инициализирует источник данных с преобразованными строками
  SyncfusionGridData convert(Dataset dataset) {
    final columns = _convertColumns(dataset.columns);
    final source = DatasetDataSource(dataset);

    return SyncfusionGridData(
      columns: columns,
      source: source,
    );
  }

  /// Преобразует колонки датасета в формат Syncfusion GridColumn
  /// 
  /// Принимает:
  /// - [columns] — список колонок датасета
  /// 
  /// Возвращает:
  /// - [List<GridColumn>] — колонки для Syncfusion DataGrid
  /// 
  /// Особенности:
  /// - Каждая колонка получает имя из датасета
  /// - Заголовок колонки отображается в контейнере с отступами
  /// - Выравнивание содержимого по левому краю
  List<GridColumn> _convertColumns(List<DataColumn> columns) {
    return columns.map((column) {
      return GridColumn(
        columnName: column.name,
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          child: Text(column.name),
        ),
      );
    }).toList();
  }
}