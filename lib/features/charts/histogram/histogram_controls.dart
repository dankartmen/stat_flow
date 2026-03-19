import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import 'histogram_state.dart';

/// {@template histogram_controls}
/// Фабрика для создания элементов управления гистограммой
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением гистограммы:
/// - Выбор числовой колонки для анализа
/// - Настройка количества корзин (bins) через слайдер
/// {@endtemplate}
class HistogramControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние гистограммы
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required Dataset dataset,
    required HistogramState state,
    required ValueChanged<HistogramState> onChanged,
  }) {
    final columns = dataset.numericColumns;

    return [
      // Выбор колонки для гистограммы
      DropdownButton<String>(
        hint: const Text("Колонка"),
        value: state.columnName,
        items: columns.map((c) {
          return DropdownMenuItem(value: c.name, child: Text(c.name));
        }).toList(),
        onChanged: (v) => onChanged(state.copyWith(columnName: v)),
      ),

      const SizedBox(width: 20),

      // Настройка количества корзин
      Row(
        children: [
          const Text("Корзины"),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: Slider(
              value: state.bins.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              label: state.bins.toString(),
              onChanged: (v) => onChanged(state.copyWith(bins: v.toInt())),
            ),
          ),
        ],
      ),
    ];
  }
}