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
class RightDatasetPanel extends StatelessWidget {
  /// Датасет для отображения информации
  final Dataset dataset;

  /// Флаг, указывающий, развернута ли панель
  final bool isExpanded;

  /// {@macro right_dataset_panel}
  const RightDatasetPanel({
    super.key,
    required this.dataset,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            if (isExpanded) ...[
            // Заголовок с основной информацией о датасете
            _buildHeader(),

            // Список полей датасета
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Поля',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...dataset.columns.map((column) => _buildColumnItem(column)),
                ],
              ),
            ),

            // Краткая статистика по типам данных
            _buildTypeStatistics(),
          ]
        ],
      ),
    );
  }

  /// Строит заголовок панели с основной информацией о датасете
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Датасет',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dataset.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                label: '${dataset.rowCount} строк',
                icon: Icons.table_rows,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: '${dataset.columnCount} колонок',
                icon: Icons.view_column,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Строит элемент списка для отдельной колонки датасета
  /// 
  /// Принимает:
  /// - [column] — колонка датасета
  /// 
  /// Возвращает:
  /// - [Widget] — визуальное представление колонки с иконкой, названием и количеством значений
  /// 
  /// Особенности:
  /// - Иконка и цвет зависят от типа колонки:
  ///   - Числовые → Icons.numbers (синий)
  ///   - Текстовые → Icons.text_fields (оранжевый)
  ///   - Дата/время → Icons.calendar_today (фиолетовый)
  ///   - Категориальные → Icons.category (зеленый)
  ///   - Остальные → Icons.label (серый)
  /// - Справа отображается количество значений в колонке
  Widget _buildColumnItem(DataColumn column) {
    IconData getIcon() {
      if (column is NumericColumn) return Icons.numbers;
      if (column is TextColumn) return Icons.text_fields;
      if (column is DateTimeColumn) return Icons.calendar_today;
      if (column is CategoricalColumn) return Icons.category;
      return Icons.label;
    }

    Color getColor() {
      if (column is NumericColumn) return Colors.blue;
      if (column is TextColumn) return Colors.orange;
      if (column is DateTimeColumn) return Colors.purple;
      if (column is CategoricalColumn) return Colors.green;
      return Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Цветной индикатор типа
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: getColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),

          // Иконка типа
          Icon(
            getIcon(),
            size: 16,
            color: Colors.grey[600],
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

          // Количество значений
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              column.length.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Строит панель статистики по типам данных
  Widget _buildTypeStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Типы данных',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _TypeStat(
            label: 'Числовые',
            count: dataset.numericColumns.length,
            color: Colors.blue,
          ),
          const SizedBox(height: 4),
          _TypeStat(
            label: 'Категориальные',
            count: dataset.categoricalColumns.length,
            color: Colors.green,
          ),
          const SizedBox(height: 4),
          _TypeStat(
            label: 'Текстовые',
            count: dataset.textColumns.length,
            color: Colors.orange,
          ),
          const SizedBox(height: 4),
          _TypeStat(
            label: 'Дата/время',
            count: dataset.dateTimeColumns.length,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

/// {@template info_chip}
/// Информационный чип для отображения в заголовке
/// 
/// Содержит иконку и текстовую метку на полупрозрачном фоне.
/// {@endtemplate}
class _InfoChip extends StatelessWidget {
  /// Текст метки
  final String label;

  /// Иконка
  final IconData icon;

  /// {@macro info_chip}
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// {@template type_stat}
/// Элемент статистики по типу данных
/// 
/// Отображает цветной индикатор, название типа и количество колонок данного типа.
/// {@endtemplate}
class _TypeStat extends StatelessWidget {
  /// Название типа
  final String label;

  /// Количество колонок
  final int count;

  /// Цвет индикатора
  final Color color;

  /// {@macro type_stat}
  const _TypeStat({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Цветной индикатор
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),

        // Название типа
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // Количество
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}