import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
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
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required HeatmapState state,
    required ValueChanged<HeatmapState> onChanged,
    required Dataset dataset,
  }) {
    final isCorrelationMode = state.xColumn == null && state.yColumn == null;

    return [
      Column(
        children: [
          Radio<bool>(
            value: true,
            groupValue: isCorrelationMode,
            onChanged: (_) => onChanged(state.copyWith(xColumn: null, yColumn: null)),
          ),
          const Text('Все числовые поля (корреляция)'),
          Radio<bool>(
            value: false,
            groupValue: isCorrelationMode,
            onChanged: (_) => onChanged(state.copyWith(xColumn: '', yColumn: '')), // временно
          ),
          const Text('Выбрать оси'),
        ],
      ),
      if (!isCorrelationMode) ...[
        const SizedBox(height: 16),
        _buildAxisSelectors(state, onChanged, dataset),
      ],
      // Выбор палитры
      DropdownButton<HeatmapPalette>(
        value: state.palette,
        items: HeatmapPalette.values.map((p) {
          return DropdownMenuItem(value: p, child: Text(p.name));
        }).toList(),
        onChanged: (v) => onChanged(state.copyWith(palette: v!)),
      ),

      const SizedBox(width: 16),

      // Выбор режима цвета
      DropdownButton<HeatmapColorMode>(
        value: state.colorMode,
        items: HeatmapColorMode.values.map((m) {
          return DropdownMenuItem(value: m, child: Text(m.name));
        }).toList(),
        onChanged: (v) => onChanged(state.copyWith(colorMode: v!)),
      ),

      // Количество сегментов (только для дискретного режима)
      if (state.colorMode == HeatmapColorMode.discrete) ...[
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: state.segments,
          items: const [
            DropdownMenuItem(value: 5, child: Text("0.4")),
            DropdownMenuItem(value: 10, child: Text("0.2")),
            DropdownMenuItem(value: 20, child: Text("0.1")),
          ],
          onChanged: (v) => onChanged(state.copyWith(segments: v!)),
        ),
      ],

      // Переключатель режима верхнего треугольника
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: state.triangleMode,
            onChanged: (v) => onChanged(state.copyWith(triangleMode: v!)),
          ),
          const Text("Верхний треугольник"),
        ],
      ),

      const SizedBox(width: 16),

      // Кнопка кластеризации
      ElevatedButton.icon(
        onPressed: () => onChanged(state.copyWith(clusterEnabled: !state.clusterEnabled)),
        icon: Icon(
          state.clusterEnabled ? Icons.account_tree : Icons.account_tree_outlined,
        ),
        label: Text(
          state.clusterEnabled ? "Отключить кластеризацию" : "Кластеризовать",
        ),
      ),
    ];
  }
  
  static Widget _buildAxisSelectors(
    HeatmapState state,
    ValueChanged<HeatmapState> onChanged,
    Dataset dataset,
  ) {
    final columns = dataset.columns;
    final columnNames = columns.map((c) => c.name).toList();

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: state.xColumn?.isNotEmpty == true ? state.xColumn : null,
          hint: const Text('X ось'),
          items: columnNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
          onChanged: (value) => onChanged(state.copyWith(xColumn: value)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: state.yColumn?.isNotEmpty == true ? state.yColumn : null,
          hint: const Text('Y ось'),
          items: columnNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
          onChanged: (value) => onChanged(state.copyWith(yColumn: value)),
        ),
        if (_isNumericColumn(dataset, state.yColumn))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<AggregationType>(
              value: state.aggregationType,
              items: AggregationType.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
              onChanged: (value) => onChanged(state.copyWith(aggregationType: value!)),
            ),
          ),
      ],
    );
  }

  static bool _isNumericColumn(Dataset dataset, String? columnName) {
    if (columnName == null) return false;
    final col = dataset.column(columnName);
    return col is NumericColumn;
  }
}