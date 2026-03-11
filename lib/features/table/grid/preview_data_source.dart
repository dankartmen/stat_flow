import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// {@template preview_data_source}
/// Источник данных для предварительного просмотра таблицы в Syncfusion DataGrid
/// 
/// Отвечает за:
/// - Преобразование сырых строковых данных в формат DataGridRow
/// - Построение ячеек таблицы с ограничением текста и отступами
/// - Уведомление об изменениях данных
/// 
/// Используется при предварительном просмотре CSV-файла перед полной загрузкой.
/// {@endtemplate}
class PreviewDataSource extends DataGridSource {
  /// Заголовки колонок
  final List<String> headers;

  /// Строки данных (список списков строковых значений)
  final List<List<String>> dataRows;

  /// Внутреннее хранилище строк для DataGrid
  late List<DataGridRow> _dataGridRows;

  /// {@macro preview_data_source}
  PreviewDataSource(this.headers, this.dataRows) {
    _buildRows();
  }

  /// Строит строки данных из предоставленных данных
  /// 
  /// Особенности:
  /// - Каждая строка преобразуется в [DataGridRow]
  /// - Количество ячеек соответствует количеству заголовков
  /// - Если в строке меньше значений, чем заголовков, недостающие заполняются пустой строкой
  void _buildRows() {
    _dataGridRows = dataRows.map((row) {
      final cells = <DataGridCell>[];

      for (int i = 0; i < headers.length; i++) {
        final value = i < row.length ? row[i] : '';
        cells.add(DataGridCell<String>(columnName: headers[i], value: value));
      }

      return DataGridRow(cells: cells);
    }).toList();
  }

  /// Возвращает список строк для отображения
  @override
  List<DataGridRow> get rows => _dataGridRows;

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
  /// - Текст обрезается с многоточием при переполнении
  /// - Размер шрифта 12 пикселей
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8),
          child: Text(
            cell.value?.toString() ?? '',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }

  /// Обновляет данные источника
  /// 
  /// Вызывает перестроение строк и уведомляет подписчиков об изменениях.
  /// Используется после обновления данных в источнике.
  void updateDataSource() {
    _buildRows();
    notifyListeners();
  }
}