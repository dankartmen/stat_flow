import 'package:flutter/material.dart';

import '../../../core/dataset/dataset.dart';
import 'boxplot_state.dart';

/// {@template boxplot_controls}
/// Фабрика для создания элементов управления ящика с усами (box plot)
/// 
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением ящика с усами:
/// - Выбор числовой колонки для анализа
/// 
/// Элементы управления адаптируются под текущий датасет и состояние.
/// {@endtemplate}
class BoxPlotControls {
  /// Строит список виджетов управления на основе состояния
  /// 
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние ящика с усами
  /// - [refresh] — callback для обновления UI после изменения состояния
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  /// 
  /// Особенности:
  /// - Автоматически получает список числовых колонок из датасета
  /// - При отсутствии числовых колонок Dropdown будет пустым
  /// - Позволяет выбрать только одну колонку для отображения
  static List<Widget> build(
    Dataset dataset,
    BoxPlotState state,
    VoidCallback refresh,
  ) {
    final columns = dataset.numericColumns;

    return [
      // Выбор колонки для ящика с усами
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
    ];
  }
}