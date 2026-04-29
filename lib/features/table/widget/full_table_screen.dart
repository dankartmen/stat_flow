import 'package:flutter/material.dart' hide DataColumn;
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/table/grid/syncfusion_grid_data.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../statistics/widgets/statistic_widget.dart';

/// {@template full_table_screen}
/// Экран полного отображения таблицы данных с расширенными возможностями.
///
/// Предоставляет:
/// - Отображение всех строк и колонок датасета в Syncfusion DataGrid.
/// - Выбор отображаемых колонок через боковую панель (планируется).
/// - Сортировку, фильтрацию и изменение размера колонок.
/// - Множественный выбор записей.
/// - Экспорт данных в различные форматы (PDF, CSV, изображение) — через стандартные возможности DataGrid.
///
/// Экран имеет три вкладки: "Данные" (таблица), "Статистика" (сводка по числовым колонкам) и "Выводы".
/// Открывается в полноэкранном режиме поверх основного интерфейса.
///
/// TODO(developer): Добавить панель выбора отображаемых колонок
/// TODO(developer): Реализовать экспорт данных
/// {@endtemplate}
class FullTableScreen extends StatefulWidget {
  /// Датасет для отображения.
  final Dataset dataset;

  /// {@macro full_table_screen}
  const FullTableScreen({
    super.key,
    required this.dataset,
  });

  @override
  State<FullTableScreen> createState() => _FullTableScreenState();
}

/// Состояние экрана полной таблицы.
/// Управляет подготовкой данных для DataGrid и переключением между вкладками.
class _FullTableScreenState extends State<FullTableScreen> {
  /// Подготовленные данные и колонки для Syncfusion DataGrid.
  ///
  /// Создаётся в [initState] с помощью [SyncfusionGridConverter].
  /// Утилизируется в [dispose] через вызов [dispose] у источника данных.
  late SyncfusionGridData _gridData;

  @override
  void initState() {
    super.initState();
    _gridData = SyncfusionGridConverter().convert(widget.dataset);
  }

  @override
  void dispose() {
    // Освобождаем ресурсы источника данных DataGrid (отписываемся от слушателей и т.п.)
    _gridData.source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Данные'),
              Tab(text: 'Статистика'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Container(
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
                ),
                StatisticsTable(dataset: widget.dataset),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template table_header}
/// Внутренний виджет заголовка экрана полной таблицы с названием и кнопкой закрытия.
///
/// Расположен в верхней части экрана и обеспечивает быстрый доступ к закрытию просмотра таблицы.
/// Содержит:
/// - Название "Таблица данных".
/// - Кнопку "Закрыть", которая закрывает экран и возвращает пользователя к основному интерфейсу.
/// {@endtemplate}
class _TableHeader extends StatelessWidget {
  /// {@macro table_header}
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
          // Кнопка закрытия экрана
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}