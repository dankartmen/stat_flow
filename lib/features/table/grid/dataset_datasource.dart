import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../core/dataset/dataset.dart';

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

  /// Список строк, построенных из датасета для отображения
  final Map<int, DataGridRow> _rowCache = {};

  /// {@macro dataset_data_source}
  DatasetDataSource(this.dataset){
     WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  /// Количество строк в датасете
  int get rowsCount => dataset.rowCount;

  /// Получает строку для отображения по индексу. Использует кэш для оптимизации производительности при повторных запросах.
  /// Если строка не найдена в кэше, строит ее из датасета и сохраняет в кэше. Ограничивает размер кэша, чтобы предотвратить чрезмерное потребление памяти.
  @override
  List<DataGridRow> get rows => List.generate(rowsCount, (i) => getRow(i));

  /// Получает строку для отображения по индексу. Использует кэш для оптимизации производительности при повторных запросах.
  /// Если строка не найдена в кэше, строит ее из датасета и сохраняет в кэше. Ограничивает размер кэша, чтобы предотвратить чрезмерное потребление памяти.
  /// 
  /// Параметры:
  /// - [index]: индекс строки, которую нужно получить
  /// Возвращает: DataGridRow, соответствующий строке датасета с данным индексом
  
  DataGridRow getRow(int index) {
    if (_rowCache.containsKey(index)) {
      return _rowCache[index]!;
    }
    
    final row = DataGridRow(
      cells: dataset.columns.map((column) {
        return DataGridCell(
          columnName: column.name,
          value: column[index],
        );
      }).toList(),
    );
    
    // Ограничим размер кэша, чтобы не разрастался слишком сильно (например, 500 строк)
    if (_rowCache.length > 500) {
      _rowCache.remove(_rowCache.keys.first);
    }
    _rowCache[index] = row;
    return row;
  }

  /// Построение виджета для отображения строки в таблице. Преобразует DataGridRow в DataGridRowAdapter с соответствующим форматированием ячеек.
  /// Параметры:
  /// - [row]: DataGridRow, который нужно отобразить
  /// Возвращает: DataGridRowAdapter, содержащий виджеты для отображения ячеек строки
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
  
  /// Обновляет источник данных, очищая кэш строк и уведомляя слушателей об изменении данных. Вызывается при изменении датасета.
  void updateDataSource() {
    _rowCache.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
    _rowCache.clear();
  }
}