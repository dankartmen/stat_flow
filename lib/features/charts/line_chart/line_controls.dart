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
/// - Включение/отключение сглаживания (если есть)
/// - Включение/отключение сетки
/// {@endtemplate}
class LineControls {
  /// Строит список виджетов управления на основе состояния
  static List<Widget> build({
    required Dataset dataset,
    required LineState state,
    required ValueChanged<LineState> onChanged,
  }) {
    final columns = dataset.numericColumns;

    return [
      // Выбор колонки для оси Y
      DropdownButton<String>(
        hint: const Text("Ось Y"),
        value: state.columnName,
        items: columns.map((c) {
          return DropdownMenuItem(value: c.name, child: Text(c.name));
        }).toList(),
        onChanged: (v) => onChanged(state.copyWith(columnName: v)),
      ),

      const SizedBox(width: 16),

      // Маркеры
      Row(
        children: [
          const Text("Маркеры"),
          const SizedBox(width: 4),
          Checkbox(
            value: state.showMarkers,
            onChanged: (v) => onChanged(state.copyWith(showMarkers: v ?? false)),
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
            onChanged: (v) => onChanged(state.copyWith(showGridLines: v ?? false)),
          ),
        ],
      ),
    ];
  }
}