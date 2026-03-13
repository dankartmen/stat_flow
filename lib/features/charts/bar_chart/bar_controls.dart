import 'package:flutter/material.dart';

import '../../../core/dataset/dataset.dart';
import 'bar_state.dart';

/// {@template bar_controls}
/// Фабрика для создания элементов управления столбчатой диаграммой
/// {@endtemplate}
class BarControls {
  static List<Widget> build(
    Dataset dataset,
    BarState state,
    VoidCallback refresh,
  ) {
    final columns = dataset.numericColumns;

    return [
      // Выбор колонки
      DropdownButton<String>(
        hint: const Text("Колонка"),
        value: state.columnName,
        items: columns.map((c) {
          return DropdownMenuItem(
            value: c.name,
            child: Text(c.name),
          );
        }).toList(),
        onChanged: (v) {
          state.columnName = v;
          refresh();
        },
      ),

      const SizedBox(width: 16),

      // Показывать значения
      Row(
        children: [
          const Text("Значения"),
          const SizedBox(width: 4),
          Checkbox(
            value: state.showValues,
            onChanged: (v) {
              state.showValues = v ?? false;
              refresh();
            },
          ),
        ],
      ),

      const SizedBox(width: 16),

      // Ширина столбцов
      Row(
        children: [
          const Text("Ширина"),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Slider(
              value: state.barWidth,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: state.barWidth.toStringAsFixed(1),
              onChanged: (v) {
                state.barWidth = v;
                refresh();
              },
            ),
          ),
        ],
      ),

      const SizedBox(width: 16),

      // Выравнивание
      DropdownButton<BarAlignment>(
        value: state.alignment,
        items: BarAlignment.values.map((alignment) {
          return DropdownMenuItem(
            value: alignment,
            child: Text(alignment.toString().split('.').last),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) {
            state.alignment = v;
            refresh();
          }
        },
      ),
    ];
  }
}