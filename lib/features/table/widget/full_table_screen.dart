import 'package:flutter/material.dart' hide DataColumn;
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/table/grid/syncfusion_grid_data.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../statistics/widgets/statistic_widget.dart';
import '../grid/dataset_datasource.dart';

/// {@template full_table_screen}
/// Экран полного отображения таблицы данных с расширенными возможностями.
///
/// Предоставляет:
/// - Отображение всех строк и колонок датасета в Syncfusion DataGrid.
/// - Выбор отображаемых колонок через боковую панель.
/// - Сортировку, фильтрацию и изменение размера колонок.
/// - Множественный выбор записей.
/// - Экспорт данных в различные форматы (PDF, CSV, изображение) — через стандартные возможности DataGrid.
///
/// Экран имеет две вкладки: "Данные" (таблица), "Статистика" (сводка по числовым колонкам).
/// Открывается в полноэкранном режиме поверх основного интерфейса.
///
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

/// {@template full_table_screen_state}
/// Состояние экрана полной таблицы.
/// Управляет подготовкой данных для DataGrid, выбором отображаемых колонок и переключением между вкладками.
/// {@endtemplate}
class _FullTableScreenState extends State<FullTableScreen> {
  /// Подготовленные данные и колонки для Syncfusion DataGrid.
  /// Содержит источник данных [DatasetDataSource] и список [GridColumn].
  late SyncfusionGridData _gridData;

  /// Множество имён колонок, выбранных для отображения.
  /// Используется для фильтрации колонок в таблице.
  late Set<String> _selectedColumns;

  @override
  void initState() {
    super.initState();
    // Инициализируем выбор всех колонок
    _selectedColumns = widget.dataset.columns.map((c) => c.name).toSet();
    _gridData = _buildGridData(_selectedColumns);
  }

  @override
  void dispose() {
    // Освобождаем ресурсы источника данных во избежание утечек памяти
    _gridData.source.dispose();
    super.dispose();
  }

  /// Создаёт [SyncfusionGridData] на основе выбранных колонок.
  ///
  /// Принимает:
  /// - [selectedColumnNames] – имена колонок, которые должны отображаться.
  ///
  /// Возвращает объект [SyncfusionGridData], содержащий отфильтрованные колонки
  /// и источник данных для DataGrid.
  SyncfusionGridData _buildGridData(Set<String> selectedColumnNames) {
    // Создаём датасет только с выбранными колонками
    final filteredDataset = widget.dataset.select(selectedColumnNames.toList());
    // Создаём источник данных для отфильтрованного датасета
    final source = DatasetDataSource(filteredDataset);
    // Создаём колонки для отображения
    final columns = selectedColumnNames.map((colName) {
      return GridColumn(
        columnName: colName,
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          child: Text(colName),
        ),
      );
    }).toList();

    return SyncfusionGridData(
      columns: columns,
      source: source,
    );
  }

  /// Обновляет отображаемые колонки в соответствии с текущим значением [_selectedColumns].
  /// Заменяет старый [_gridData] новым, предварительно освобождая старый источник.
  void _updateGridColumns() {
    final newGridData = _buildGridData(_selectedColumns);
    // Освобождаем старый источник, чтобы избежать утечек памяти
    _gridData.source.dispose();
    setState(() {
      _gridData = newGridData;
    });
  }

  /// Показывает диалог выбора колонок для отображения.
  ///
  /// Пользователь может отметить нужные колонки, выбрать все или сбросить все.
  /// После подтверждения изменения применяются, и таблица перестраивается.
  void _showColumnSelector() {
    final allColumnNames = widget.dataset.columns.map((c) => c.name).toList();
    // Временно храним выбранные колонки в локальной переменной для возможности отмены
    Set<String> tempSelected = Set.from(_selectedColumns);

    showDialog(
      context: context,
      builder: (ctx) {
        // Используем StatefulBuilder для локального состояния диалога (предварительный выбор колонок)
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Выберите колонки для отображения'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView(
                  children: allColumnNames.map((colName) {
                    return CheckboxListTile(
                      title: Text(colName),
                      value: tempSelected.contains(colName),
                      onChanged: (checked) {
                        // Обновляем только временное состояние диалога
                        setDialogState(() {
                          if (checked == true) {
                            tempSelected.add(colName);
                          } else {
                            tempSelected.remove(colName);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Выбрать все колонки
                    setDialogState(() {
                      tempSelected = Set.from(allColumnNames);
                    });
                  },
                  child: const Text('Выбрать все'),
                ),
                TextButton(
                  onPressed: () {
                    // Сбросить все, оставить только первую колонку (если есть)
                    setDialogState(() {
                      if (allColumnNames.isNotEmpty) {
                        tempSelected = {allColumnNames.first};
                      } else {
                        tempSelected = {};
                      }
                    });
                  },
                  child: const Text('Сбросить всё'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: tempSelected.isEmpty
                      ? null
                      : () {
                          // Применяем изменения: закрываем диалог и обновляем таблицу
                          Navigator.pop(ctx);
                          _selectedColumns = tempSelected;
                          _updateGridColumns();
                        },
                  child: const Text('Применить'),
                ),
              ],
            );
          },
        );
      },
    );
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
                      _TableHeader(onSelectColumns: _showColumnSelector),
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
/// Внутренний виджет заголовка экрана полной таблицы с названием и кнопкой выбора колонок.
///
/// Расположен в верхней части экрана и обеспечивает быстрый доступ к выбору отображаемых колонок.
/// Содержит:
/// - Название "Таблица данных".
/// - Кнопку выбора колонок.
/// {@endtemplate}
class _TableHeader extends StatelessWidget {
  /// Коллбек для открытия панели выбора колонок.
  final VoidCallback onSelectColumns;

  /// {@macro table_header}
  const _TableHeader({required this.onSelectColumns});

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
          Row(
            children: [
              // Кнопка выбора колонок
              IconButton(
                icon: const Icon(Icons.view_column),
                tooltip: 'Выбрать колонки',
                onPressed: onSelectColumns,
              )
            ],
          ),
        ],
      ),
    );
  }
}