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
/// 
/// Элементы управления адаптируются под текущий датасет и состояние.
/// {@endtemplate}
class HistogramControls {
  /// Строит список виджетов управления на основе состояния
  /// 
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние гистограммы
  /// - [refresh] — callback для обновления UI после изменения состояния
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  /// 
  /// Особенности:
  /// - Автоматически получает список числовых колонок из датасета
  /// - При отсутствии числовых колонок Dropdown будет пустым
  /// - Слайдер позволяет выбирать количество корзин от 5 до 50 с шагом 5
  static List<Widget> build(
    Dataset dataset,
    HistogramState state,
    VoidCallback refresh,
  ) {
    final columns = dataset.numericColumns;

    return [
      // Выбор колонки для гистограммы
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
              divisions: 9, // 5,10,15,...,50
              label: state.bins.toString(),
              onChanged: (v) {
                state.bins = v.toInt();
                refresh();
              },
            ),
          ),
        ],
      ),
    ];
  }
}