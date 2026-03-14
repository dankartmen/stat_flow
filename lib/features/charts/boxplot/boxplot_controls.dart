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

    final maxPointsOptions = [
      1000,
      2000,
      5000,
      10000,
      0, // 0 обозначает "все" значения
    ];

    String formatMaxPoints(int value) {
      if (value <= 0) return 'Все';
      if (value >= 1000) return '${value ~/ 1000}k';
      return value.toString();
    }

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

      const SizedBox(width: 12),

      // Переключатель отображения среднего
      Tooltip(
        message: state.showMean ? 'Скрыть среднее' : 'Показать среднее',
        child: IconButton(
          icon: Icon(
            Icons.show_chart,
            color: state.showMean ? Colors.blue : Colors.black45,
          ),
          onPressed: () {
            state.showMean = !state.showMean;
            refresh();
          },
        ),
      ),

      // Переключатель отображения выбросов
      Tooltip(
        message: state.showOutliers ? 'Скрыть выбросы' : 'Показать выбросы',
        child: IconButton(
          icon: Icon(
            Icons.bubble_chart,
            color: state.showOutliers ? Colors.blue : Colors.black45,
          ),
          onPressed: () {
            state.showOutliers = !state.showOutliers;
            refresh();
          },
        ),
      ),

      const SizedBox(width: 12),

      // Ограничение по числу точек для рендеринга
      DropdownButton<int>(
        value: state.maxPoints,
        items: maxPointsOptions.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text('Точек: ${formatMaxPoints(option)}'),
          );
        }).toList(),
        onChanged: (v) {
          if (v == null) return;
          state.maxPoints = v;
          refresh();
        },
      ),
    ];
  }
}