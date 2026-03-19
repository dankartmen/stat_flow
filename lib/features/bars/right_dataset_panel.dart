import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import '../../core/providers/providers.dart';
import '../charts/chart_type.dart';

/// {@template right_dataset_panel}
/// Правая панель с информацией о загруженном датасете
/// 
/// Отображает список всех колонок датасета с возможностью:
/// - Просмотра типа данных каждой колонки (цветовой индикатор)
/// - Визуальной индикации используемых в графиках полей
/// - Быстрого создания графиков через контекстное меню (правый клик)
/// - Сворачивания/разворачивания панели
/// 
/// Панель имеет адаптивную ширину: 280px в развернутом состоянии,
/// 0px в свернутом (скрыта, видна только ручка для раскрытия).
/// {@endtemplate}
class RightDatasetPanel extends ConsumerStatefulWidget {
  /// Загруженный датасет для отображения
  final Dataset dataset;

  /// Флаг развернутого состояния панели
  final bool isExpanded;

  /// Коллбек для создания графика по выбранному полю и типу
  final Function(String fieldName, ChartType chartType) onCreateChart;

  /// {@macro right_dataset_panel}
  const RightDatasetPanel({
    super.key,
    required this.dataset,
    required this.isExpanded,
    required this.onCreateChart,
  });

  @override
  ConsumerState<RightDatasetPanel> createState() => _RightDatasetPanelState();
}

class _RightDatasetPanelState extends ConsumerState<RightDatasetPanel> {
  /// Флаг развернутого состояния списка полей (внутри панели)
  bool _fieldsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final usedFields = ref.watch(usedFieldsProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isExpanded) ...[
            _buildTitle(),
            if (_fieldsExpanded) _buildFieldsList(usedFields),
          ]
        ],
      ),
    );
  }

  /// Строит заголовок панели с кнопкой сворачивания списка полей
  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_fieldsExpanded ? Icons.expand_more : Icons.chevron_right),
            onPressed: () => setState(() => _fieldsExpanded = !_fieldsExpanded),
          ),
          Expanded(
            child: Text(
              widget.dataset.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Строит список полей датасета с сортировкой по алфавиту
  Widget _buildFieldsList(Set<String> usedFields) {
    final sortedColumns = List<DataColumn>.from(widget.dataset.columns)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: sortedColumns.map((c) => _buildFieldItem(c, usedFields)).toList(),
      ),
    );
  }

  /// Строит элемент списка для отдельного поля
  Widget _buildFieldItem(DataColumn column, Set<String> usedFields) {
    final isUsed = usedFields.contains(column.name);
    final typeColor = _getTypeColor(column);
    final availableChartTypes = _getAvailableChartTypes(column);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTap: () {
          _showChartTypeMenu(context, column, availableChartTypes);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isUsed ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              _buildUsageIndicator(isUsed),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isUsed ? FontWeight.w500 : FontWeight.normal,
                    color: isUsed ? Colors.blue[900] : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isUsed)
                Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит индикатор использования поля в графиках
  Widget _buildUsageIndicator(bool isUsed) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUsed ? Colors.blue : Colors.transparent,
        border: Border.all(
          color: isUsed ? Colors.blue : Colors.grey[400]!,
          width: isUsed ? 2 : 1,
        ),
      ),
      child: isUsed
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  /// Отображает контекстное меню с доступными типами графиков для поля
  void _showChartTypeMenu(
    BuildContext context,
    DataColumn column,
    List<ChartTypeWithIcon> chartTypes,
  ) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 300,
        offset.dy,
        0,
        0,
      ),
      items: chartTypes.map((type) {
        return PopupMenuItem(
          onTap: () => widget.onCreateChart(column.name, type.type),
          child: Row(
            children: [
              Icon(type.icon, size: 20),
              const SizedBox(width: 12),
              Text(type.name),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Определяет цвет индикатора типа данных
  Color _getTypeColor(DataColumn column) {
    if (column is NumericColumn) return Colors.blue;
    if (column is DateTimeColumn) return Colors.purple;
    if (column is CategoricalColumn) return Colors.green;
    return Colors.orange;
  }

  /// Возвращает список доступных типов графиков для данного типа колонки
  List<ChartTypeWithIcon> _getAvailableChartTypes(DataColumn column) {
    if (column is NumericColumn) {
      return const [
        ChartTypeWithIcon(
          type: ChartType.histogram,
          icon: Icons.bar_chart,
          name: 'Гистограмма',
        ),
        ChartTypeWithIcon(
          type: ChartType.boxplot,
          icon: Icons.candlestick_chart,
          name: 'Ящик с усами',
        ),
        ChartTypeWithIcon(
          type: ChartType.scatter,
          icon: Icons.bubble_chart,
          name: 'Диаграмма рассеяния',
        ),
        ChartTypeWithIcon(
          type: ChartType.linechart,
          icon: Icons.line_axis,
          name: 'Линейный график',
        ),
      ];
    } else if (column is DateTimeColumn) {
      return const [
        ChartTypeWithIcon(
          type: ChartType.linechart,
          icon: Icons.line_axis,
          name: 'Временной ряд',
        ),
        ChartTypeWithIcon(
          type: ChartType.scatter,
          icon: Icons.bubble_chart,
          name: 'Диаграмма рассеяния',
        ),
      ];
    } else if (column is CategoricalColumn || column is TextColumn) {
      return const [
        ChartTypeWithIcon(
          type: ChartType.barchart,
          icon: Icons.bar_chart,
          name: 'Столбчатая диаграмма',
        ),
      ];
    }
    return const [
      ChartTypeWithIcon(
        type: ChartType.barchart,
        icon: Icons.bar_chart,
        name: 'Столбчатая диаграмма',
      ),
    ];
  }
}

/// {@template chart_type_with_icon}
/// Вспомогательный класс для хранения информации о типе графика в меню
/// 
/// Используется для единообразного отображения пунктов меню создания графиков:
/// - Содержит тип графика для идентификации
/// - Иконку для визуального различия
/// - Локализованное название для отображения пользователю
/// {@endtemplate}
class ChartTypeWithIcon {
  /// Тип графика из перечисления [ChartType]
  final ChartType type;

  /// Иконка для отображения в меню
  final IconData icon;

  /// Отображаемое название графика
  final String name;

  /// {@macro chart_type_with_icon}
  const ChartTypeWithIcon({
    required this.type,
    required this.icon,
    required this.name,
  });
}