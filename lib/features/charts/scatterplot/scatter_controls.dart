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
  /// - [context] — контекст для доступа к теме и локализации
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required Dataset dataset,
    required ScatterState state,
    required ValueChanged<ScatterState> onChanged,
    required BuildContext context,
  }) {
    final columns = dataset.numericColumns.map((c) => c.name).toList();
    final yAxisItems = columns.where((name) => name != state.firstColumnName).toList();

    return [
      buildSection(
        title: "Оси",
        context: context,
        icon: null,
        child: Column(
          children: [
            buildDropdown(
              label: "Ось X",
              initialValue: state.firstColumnName,
              items: columns,
              onChanged: (value) => onChanged(state.copyWith(firstColumnName: value)),
              context: context,
            ),
            const SizedBox(height: 12),
            buildDropdown(
              label: "Ось Y",
              initialValue: state.secondColumnName,
              items: yAxisItems,
              onChanged: (value) => onChanged(state.copyWith(secondColumnName: value)),
              context: context,
            ),
          ],
        ),
      ),
    ];
  }
}