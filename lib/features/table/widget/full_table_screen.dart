import 'package:flutter/material.dart' hide DataColumn;
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/table/grid/syncfusion_grid_data.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// {@template full_table_screen}
/// Экран полного отображения таблицы данных с расширенными возможностями
/// 
/// Предоставляет:
/// - Отображение всех строк и колонок датасета в Syncfusion DataGrid
/// - Выбор отображаемых колонок через боковую панель
/// - Сортировку, фильтрацию и изменение размера колонок
/// - Множественный выбор записей
/// - Экспорт данных в различные форматы (PDF, CSV, изображение)
/// 
/// Экран открывается в полноэкранном режиме поверх основного интерфейса.
/// {@endtemplate}
class FullTableScreen extends StatefulWidget {
  /// Датасет для отображения
  final Dataset dataset;

  /// {@macro full_table_screen}
  const FullTableScreen({
    super.key,
    required this.dataset,
  });

  @override
  State<FullTableScreen> createState() => _FullTableScreenState();
}

class _FullTableScreenState extends State<FullTableScreen> {
  /// Подготовленные данные для Syncfusion DataGrid
  late SyncfusionGridData _gridData;

  @override
  void initState() {
    super.initState();
    final converter = SyncfusionGridConverter();
    _gridData = converter.convert(widget.dataset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Полная таблица данных'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [ 
          // Информация о датасете
          _buildDatasetInfo(),
        ],
      ),
      body: SfDataGrid(
        source: _gridData.source,
        columns: _gridData.columns,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
        allowSorting: true,
        allowMultiColumnSorting: true,
        allowTriStateSorting: true,
        allowFiltering: true,
        allowColumnsResizing: true,
        selectionMode: SelectionMode.multiple,
        navigationMode: GridNavigationMode.cell,
        columnWidthMode: ColumnWidthMode.auto,
        defaultColumnWidth: 100.0,
        rowHeight: 40.0,
        headerRowHeight: 50.0,
        isScrollbarAlwaysShown: true,
        frozenColumnsCount: 0,
      ),
    );
  }


  /// Строит информационную панель с количеством строк и колонок
  Widget _buildDatasetInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${widget.dataset.rowCount} строк',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: Colors.white30,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.dataset.columnCount} колонок',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
