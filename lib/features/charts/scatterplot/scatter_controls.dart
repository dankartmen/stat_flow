import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import 'scatter_state.dart';

/// {@template scatter_controls}
/// Фабрика для создания элементов управления диаграммой рассеяния
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением scatter plot:
/// - Выбор первой числовой колонки (ось X)
/// - Выбор второй числовой колонки (ось Y)
///
/// Элементы управления адаптируются под текущий датасет и состояние.
/// {@endtemplate}
class ScatterControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние диаграммы рассеяния
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required Dataset dataset,
    required ScatterState state,
    required ValueChanged<ScatterState> onChanged,
  }) {
    final columns = dataset.numericColumns;

    return [
      // Выбор первой колонки (ось X)
      DropdownButton<String>(
        hint: const Text("Ось X"),
        value: state.firstColumnName,
        items: columns.map((c) {
          return DropdownMenuItem(value: c.name, child: Text(c.name));
        }).toList(),
        onChanged: (v) {
          // Если выбрана та же колонка, что и для Y, сбрасываем Y
          final newSecond = (v == state.secondColumnName) ? null : state.secondColumnName;
          onChanged(state.copyWith(firstColumnName: v, secondColumnName: newSecond));
        },
      ),

      const SizedBox(width: 16),

      // Выбор второй колонки (ось Y)
      DropdownButton<String>(
        hint: const Text("Ось Y"),
        value: state.secondColumnName,
        items: columns
            .where((c) => c.name != state.firstColumnName)
            .map((c) {
              return DropdownMenuItem(value: c.name, child: Text(c.name));
            }).toList(),
        onChanged: (v) => onChanged(state.copyWith(secondColumnName: v)),
      ),
    ];
  }
}