import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../dataset/dataset.dart';

/// {@template dataset_data_source}
/// Источник данных для Syncfusion DataGrid, адаптирующий [Dataset] к формату DataGridSource
/// 
/// Отвечает за:
/// - Преобразование строк датасета в формат DataGridRow
/// - Построение ячеек таблицы с соответствующим форматированием
/// - Предоставление данных для отображения в Syncfusion DataGrid
/// {@endtemplate}
class DatasetDataSource extends DataGridSource {
  /// Датасет, который будет отображаться в таблице
  final Dataset dataset;

  /// Внутреннее хранилище строк данных для DataGrid
  late List<DataGridRow> _rows;

  /// {@macro dataset_data_source}
  DatasetDataSource(this.dataset) {
    _buildRows();
  }

  /// Строит строки данных из датасета
  /// 
  /// Особенности:
  /// - Количество строк определяется по [dataset.rowCount]
  /// - Для каждой строки создается [DataGridRow] с ячейками для всех колонок
  void _buildRows() {
    final rowCount = dataset.rowCount;

    _rows = List.generate(rowCount, (index) {
      return DataGridRow(
        cells: dataset.columns.map((column) {
          return DataGridCell(
            columnName: column.name,
            value: column[index],
          );
        }).toList(),
      );
    });
  }

  /// Возвращает список строк для отображения
  @override
  List<DataGridRow> get rows => _rows;

  /// Строит визуальное представление строки
  /// 
  /// Принимает:
  /// - [row] — строка данных для отображения
  /// 
  /// Возвращает:
  /// - [DataGridRowAdapter] — адаптер с настроенными ячейками
  /// 
  /// Особенности:
  /// - Каждая ячейка выравнивается по левому краю
  /// - Устанавливается отступ в 8 пикселей
  /// - Пустые значения отображаются как пустая строка
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8),
          child: Text(cell.value?.toString() ?? ''),
        );
      }).toList(),
    );
  }
}