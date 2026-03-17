import 'package:flutter/material.dart' hide DataColumn;
import 'package:stat_flow/core/dataset/dataset.dart';

/// {@template right_dataset_panel}
/// Правая боковая панель с информацией о загруженном датасете
/// 
/// Отображает детальную информацию о датасете:
/// - Название файла
/// - Количество строк и колонок
/// - Список всех полей с их типами и количеством значений
/// - Статистику по типам данных (числовые, категориальные, текстовые, дата/время)
/// 
/// Панель имеет фиксированную ширину 280 пикселей и обновляется при загрузке нового датасета.
/// {@endtemplate}
class RightDatasetPanel extends StatefulWidget {
  /// Датасет для отображения информации
  final Dataset dataset;

  /// Флаг, указывающий, развернута ли панель
  final bool isExpanded;

  /// Callback для создания графика на основе выбранного поля
  final ValueChanged<String> onCreateChart;
  
  /// {@macro right_dataset_panel}
  const RightDatasetPanel({
    super.key,
    required this.dataset,
    required this.isExpanded,
    required this.onCreateChart,
  });

  @override
  State<RightDatasetPanel> createState() => _RightDatasetPanelState();
}

class _RightDatasetPanelState extends State<RightDatasetPanel> {
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

  Widget _buildTitle(){
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.dataset.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(_fieldsExpanded ? Icons.expand_more: Icons.chevron_right),
            onPressed: () => setState(() => _fieldsExpanded = !_fieldsExpanded),
          )
        ],
      ),
    );
  }

  Widget _buildFieldsList(){
    final sortedColumns = List<DataColumn>.from(widget.dataset.columns)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Expanded(
      child: ListView(
        padding:  const EdgeInsets.all(16),
        children: sortedColumns.map((c) => _buildFieldItem(c)).toList(),
      ),
    );
  }

  Widget _buildFieldItem(DataColumn column){
    Color typeColor;

    if (column is NumericColumn) {
      typeColor = Colors.blue;
    } else if (column is DateTimeColumn) {
      typeColor = Colors.purple;
    } else if (column is CategoricalColumn) {
      typeColor = Colors.green;
    } else {
      typeColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Кнопка построения графика
          IconButton(
            icon: const Icon(Icons.add_chart, size: 18),
            onPressed: () => widget.onCreateChart(column.name),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
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
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}