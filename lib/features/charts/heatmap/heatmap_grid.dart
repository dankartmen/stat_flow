import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/correlation_matrix.dart';

import 'correlation_color_scale.dart';

/// {@template heatmap_grid}
/// Сетка тепловой карты
/// {@endtemplate}
class HeatmapGrid extends StatelessWidget {
  /// Матрица корреляции
  final CorrelationMatrix matrix;

  /// Размеры ячеек
  static const double cellWidth = 60;
  static const double cellHeight = 40;
  static const double headerWidth = 80;

  /// {@macro heatmap_grid}
  const HeatmapGrid({required this.matrix, super.key});

  @override
  Widget build(BuildContext context) {
    if (matrix.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnHeaders(),
        ...List.generate(matrix.size, (i) => _buildRow(i)),
      ],
    );
  }

  /// Заголовки столбцов
  Widget _buildColumnHeaders() {
    return Row(
      children: [
        const SizedBox(width: headerWidth),
        ...List.generate(matrix.size, (i) => _HeaderCell(
          width: cellWidth,
          height: 30,
          text: matrix.fieldNames[i],
        )),
      ],
    );
  }

  /// Строка тепловой карты
  Widget _buildRow(int rowIndex) {
    return Row(
      children: [
        _HeaderCell(
          width: headerWidth,
          height: cellHeight,
          text: matrix.fieldNames[rowIndex],
          alignRight: true,
        ),
        ...List.generate(matrix.size, (colIndex) {
          final value = matrix.getByIndex(rowIndex, colIndex);
          return _HeatmapCell(value: value);
        }),
      ],
    );
  }
}

/// Ячейка заголовка
class _HeaderCell extends StatelessWidget {
  final double width;
  final double height;
  final String text;
  final bool alignRight;

  const _HeaderCell({
    required this.width,
    required this.height,
    required this.text,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignRight ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        _shorten(text),
        maxLines: 2,
        textAlign: alignRight ? TextAlign.right : TextAlign.center,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Укорачивание длинных подписей
  String _shorten(String text) {
    if (text.length <= 10) return text;
    return '${text.substring(0, 9)}…';
  }
}

/// Ячейка тепловой карты
class _HeatmapCell extends StatelessWidget {
  final double value;

  const _HeatmapCell({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = _colorForValue(value);
    final textColor = value.abs() > 0.4 ? Colors.white : Colors.black;

    return Container(
      width: HeatmapGrid.cellWidth,
      height: HeatmapGrid.cellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        value.toStringAsFixed(2),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Цвет по значению корреляции
  Color _colorForValue(double v) {
    return correlationColorScale.firstWhere((range) => range.contains(v)).color;
  }
}