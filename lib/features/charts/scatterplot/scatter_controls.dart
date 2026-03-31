import 'package:flutter/material.dart';
import 'package:stat_flow/core/theme/controls_style.dart';
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
      buildSection(
        title: Text("Оси", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        child: Column(
          children: [
            buildDropdown(
              label: "Ось X",
              initialValue: state.firstColumnName,
              items: columns.map((c) => c.name).toList(),
              onChanged: (value) => onChanged(state.copyWith(firstColumnName: value)),
            ),
            const SizedBox(height: 12),
            buildDropdown(
              label: "Ось Y",
              initialValue: state.secondColumnName,
              items: columns.map((c) => c.name).where((name) => name != state.firstColumnName).toList(),
              onChanged: (value) => onChanged(state.copyWith(secondColumnName: value)),
            ),
          ],
        )
      ),
    ];
  }
}