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
    _gridData = SyncfusionGridConverter().convert(widget.dataset);
  }

  @override
  void dispose() {
    _gridData.source.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);  
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          const _TableHeader(),
          const Divider(),
          Expanded(
            child: SfDataGrid(
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
          ),
        ],
      ),
    );
  }
}

///{@template table_header}
/// Заголовок экрана полной таблицы с названием и кнопкой закрытия
/// Расположен в верхней части экрана и обеспечивает быстрый доступ к закрытию просмотра таблицы
/// Содержит:
/// - Название "Таблица данных"
/// - Кнопку "Закрыть", которая закрывает экран и возвращает пользователя к основному интерфейсу
///{@endtemplate}
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Таблица данных',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}