import 'package:flutter/material.dart';

import '../../../core/dataset/dataset.dart';
import 'line_state.dart';

/// {@template line_controls}
/// Фабрика для создания элементов управления линейным графиком
/// 
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением линейного графика:
/// - Выбор числовой колонки для оси Y
/// - Включение/отключение маркеров
/// - Включение/отключение сглаживания
/// - Включение/отключение сетки
/// {@endtemplate}
class LineControls {
  /// Строит список виджетов управления на основе состояния
  static List<Widget> build(
    Dataset dataset,
    LineState state,
    VoidCallback refresh,
  ) {
    final columns = dataset.numericColumns;

    return [
      // Выбор колонки для оси Y
      DropdownButton<String>(
        hint: const Text("Ось Y"),
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

      // Маркеры
      Row(
        children: [
          const Text("Маркеры"),
          const SizedBox(width: 4),
          Checkbox(
            value: state.showMarkers,
            onChanged: (v) {
              state.showMarkers = v ?? false;
              refresh();
            },
          ),
        ],
      ),


      const SizedBox(width: 16),

      // Сетка
      Row(
        children: [
          const Text("Сетка"),
          const SizedBox(width: 4),
          Checkbox(
            value: state.showGridLines,
            onChanged: (v) {
              state.showGridLines = v ?? false;
              refresh();
            },
          ),
        ],
      ),
    ];
  }
}