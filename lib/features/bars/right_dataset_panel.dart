import 'package:flutter/material.dart' hide DataColumn;
import 'package:stat_flow/core/dataset/dataset.dart';
import '../charts/chart_type.dart';

/// {@template right_dataset_panel}
/// Правая боковая панель с информацией о загруженном датасете
/// 
/// Отображает детальную информацию о датасете:
/// - Название файла с возможностью сворачивания/разворачивания списка полей
/// - Список всех полей с их типами и индикаторами использования
/// - Контекстное меню для создания графиков из выбранного поля (правый клик)
/// 
/// Панель имеет анимированную ширину и обновляется при загрузке нового датасета.
/// {@endtemplate}
class RightDatasetPanel extends StatefulWidget {
  /// Датасет для отображения информации
  final Dataset dataset;

  /// Флаг, указывающий, развернута ли панель
  final bool isExpanded;

  /// Callback для создания графика на основе выбранного поля
  final Function(String fieldName, ChartType chartType) onCreateChart;
  
  /// Множество полей, уже используемых в графиках (для визуальной индикации)
  final Set<String> usedFields;

  /// {@macro right_dataset_panel}
  const RightDatasetPanel({
    super.key,
    required this.dataset,
    required this.isExpanded,
    required this.onCreateChart,
    required this.usedFields
  });

  @override
  State<RightDatasetPanel> createState() => _RightDatasetPanelState();
}

class _RightDatasetPanelState extends State<RightDatasetPanel> {
  /// Флаг развернутости списка полей
  bool _fieldsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isExpanded)...[
            _buildTitle(),
            if (_fieldsExpanded) _buildFieldsList(),
          ]
        ]
      )
    );
  }

  /// Строит заголовок панели с кнопкой сворачивания
  Widget _buildTitle(){
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

  /// Строит список полей датасета
  Widget _buildFieldsList(){
    final sortedColumns = List<DataColumn>.from(widget.dataset.columns)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: sortedColumns.map((c) => _buildFieldItem(c)).toList(),
      ),
    );
  }

  /// Строит элемент списка для отдельного поля
  Widget _buildFieldItem(DataColumn column) {
    final isUsed = widget.usedFields.contains(column.name);
    final typeColor = _getTypeColor(column);
    final availableChartTypes = _getAvailableChartTypes(column);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTap: () {
          // Открываем контекстное меню при правом клике
          _showChartTypeMenu(context, column, availableChartTypes);
        },
        onTap: () {
          // Левый клик можно использовать для чего-то другого,
          // например, для выбора поля (будущее расширение)
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isUsed ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Индикатор использования поля
              _buildUsageIndicator(isUsed),
              const SizedBox(width: 8),
              
              // Цветной индикатор типа
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              
              // Название колонки
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
              
              // Подсказка о правом клике
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

  /// Строит индикатор использования поля
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

  /// Показывает меню выбора типа графика
  /// 
  /// Принимает:
  /// - [context] — BuildContext для отображения меню
  /// - [column] — колонка, для которой создается график
  /// - [chartTypes] — список доступных типов графиков
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
        offset.dx + 300, // примерно ширина панели
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

  /// Возвращает цвет в зависимости от типа колонки
  Color _getTypeColor(DataColumn column) {
    if (column is NumericColumn) return Colors.blue;
    if (column is DateTimeColumn) return Colors.purple;
    if (column is CategoricalColumn) return Colors.green;
    return Colors.orange; // TextColumn или другие
  }

  /// Возвращает список доступных типов графиков для данного типа колонки
  List<ChartTypeWithIcon> _getAvailableChartTypes(DataColumn column) {
    if (column is NumericColumn) {
      return [
        const ChartTypeWithIcon(
          type: ChartType.histogram,
          icon: Icons.bar_chart,
          name: 'Гистограмма',
        ),
        const ChartTypeWithIcon(
          type: ChartType.boxplot,
          icon: Icons.candlestick_chart,
          name: 'Ящик с усами',
        ),
        const ChartTypeWithIcon(
          type: ChartType.scatter,
          icon: Icons.bubble_chart,
          name: 'Диаграмма рассеяния',
        ),
        const ChartTypeWithIcon(
          type: ChartType.linechart,
          icon: Icons.line_axis,
          name: 'Линейный график',
        ),
      ];
    } else if (column is DateTimeColumn) {
      return [
        const ChartTypeWithIcon(
          type: ChartType.linechart,
          icon: Icons.line_axis,
          name: 'Временной ряд',
        ),
        const ChartTypeWithIcon(
          type: ChartType.scatter,
          icon: Icons.bubble_chart,
          name: 'Диаграмма рассеяния',
        ),
      ];
    } else if (column is CategoricalColumn || column is TextColumn) {
      return [
        const ChartTypeWithIcon(
          type: ChartType.barchart,
          icon: Icons.bar_chart,
          name: 'Столбчатая диаграмма',
        ),
      ];
    }
    
    return [
      const ChartTypeWithIcon(
        type: ChartType.barchart,
        icon: Icons.bar_chart,
        name: 'Столбчатая диаграмма',
      ),
    ];
  }
}

/// {@template chart_type_with_icon}
/// Вспомогательный класс для хранения информации о типе графика в меню
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