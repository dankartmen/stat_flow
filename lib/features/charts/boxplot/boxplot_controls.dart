import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import 'boxplot_state.dart';

/// {@template boxplot_controls}
/// Фабрика для создания элементов управления ящика с усами (box plot)
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением ящика с усами:
/// - Выбор числовой колонки для анализа
/// - Включение отображения среднего
/// - Включение отображения выбросов
/// - Ограничение числа точек для рендеринга
/// {@endtemplate}
class BoxPlotControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние ящика с усами
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required Dataset dataset,
    required BoxPlotState state,
    required ValueChanged<BoxPlotState> onChanged,
  }) {
    final columns = dataset.numericColumns;

    final maxPointsOptions = [1000, 2000, 5000, 10000, 0];

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
        onChanged: (v) => onChanged(state.copyWith(columnName: v)),
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
          onPressed: () => onChanged(state.copyWith(showMean: !state.showMean)),
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
          onPressed: () => onChanged(state.copyWith(showOutliers: !state.showOutliers)),
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
          if (v != null) onChanged(state.copyWith(maxPoints: v));
        },
      ),
    ];
  }
}