import 'package:flutter/material.dart';

import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_state.dart';

/// {@template heatmap_controls}
/// Фабрика для создания элементов управления тепловой картой
/// 
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением тепловой карты:
/// - Выбор цветовой палитры
/// - Выбор режима раскраски (дискретный/градиентный)
/// - Настройка количества сегментов (для дискретного режима)
/// - Переключение режима верхнего треугольника
/// - Включение/отключение кластеризации
/// {@endtemplate}
class HeatmapControls {
  /// Строит список виджетов управления на основе состояния
  /// 
  /// Принимает:
  /// - [state] — текущее состояние тепловой карты
  /// - [refresh] — callback для обновления UI после изменения состояния
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build(
    HeatmapState state,
    VoidCallback refresh
  ) {
    return [
      // Выбор палитры
      DropdownButton<HeatmapPalette>(
        value: state.palette,
        items: HeatmapPalette.values.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Text(p.name),
          );
        }).toList(),
        onChanged: (v) {
          state.palette = v!;
          refresh();
        },
      ),

      const SizedBox(width: 16),

      // Выбор режима цвета
      DropdownButton<HeatmapColorMode>(
        value: state.colorMode,
        items: HeatmapColorMode.values.map((m) {
          return DropdownMenuItem(
            value: m,
            child: Text(m.name),
          );
        }).toList(),
        onChanged: (v) {
          state.colorMode = v!;
          refresh();
        },
      ),

      // Количество сегментов (только для дискретного режима)
      if (state.colorMode == HeatmapColorMode.discrete)...[
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: state.segments,
          items: const [
            DropdownMenuItem(value: 5, child: Text("0.4")),
            DropdownMenuItem(value: 10, child: Text("0.2")),
            DropdownMenuItem(value: 20, child: Text("0.1")),
          ],
          onChanged: (v) {
            state.segments = v!;
            refresh();
          },
        ),
      ],

      // Переключатель режима верхнего треугольника
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: state.triangleMode,
            onChanged: (v) {
              state.triangleMode = v!;
              refresh();
            },
          ),
          const Text("Верхний треугольник"),
        ],
      ),

      const SizedBox(width: 16),

      // Кнопка кластеризации
      ElevatedButton.icon(
        onPressed: () {
          state.clusterEnabled = !state.clusterEnabled;
          refresh();
        },
        icon: Icon(
          state.clusterEnabled
              ? Icons.account_tree
              : Icons.account_tree_outlined,
        ),
        label: Text(
          state.clusterEnabled
              ? "Отключить кластеризацию"
              : "Кластеризовать",
        ),
      ),
    ];
  }
}