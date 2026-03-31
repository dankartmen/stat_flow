import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import '../../../../core/theme/controls_style.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_state.dart';

/// {@template heatmap_controls}
/// Фабрика для создания элементов управления тепловой картой
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением тепловой карты. Все настройки сгруппированы
/// в логические секции: режим, оси, агрегация, нормализация, сортировка,
/// проценты, цвет, отображение.
/// {@endtemplate}
class HeatmapControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [state] — текущее состояние тепловой карты
  /// - [onChanged] — колбэк для обновления состояния
  /// - [dataset] — датасет для получения списка колонок
  ///
  /// Возвращает список виджетов, которые можно разместить в панели настроек.
  static List<Widget> build({
    required HeatmapState state,
    required ValueChanged<HeatmapState> onChanged,
    required Dataset dataset,
  }) {
    final isCorrelationMode = state.useCorrelation;
    final numericColumns = dataset.numericColumns;

    return [
      // Режим (корреляция / оси)
      buildSection(
        title: Text('Режим', style: TextStyle(fontSize: 14)),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: true,
              label: Text('Корреляция всех числовых полей'),
              icon: Icon(Icons.show_chart),
            ),
            ButtonSegment<bool>(
              value: false,
              label: Text('Выбрать оси'),
              icon: Icon(Icons.swap_horiz),
            ),
          ],
          selected: {isCorrelationMode},
          onSelectionChanged: (Set<bool> selection) {
            final newMode = selection.first;
            if (newMode != isCorrelationMode) {
              onChanged(state.copyWith(
                useCorrelation: newMode,
                xColumn: null,
                yColumn: null,
              ));
            }
          },
        ),
      ),

      // Выбор осей (только если не корреляция)
      if (!isCorrelationMode) ...[
        buildSection(
          title: Text('Оси', style: TextStyle(fontSize: 14)),
          child: Column(
            children: [
              buildDropdown<String>(
                label: 'X ось',
                initialValue: state.xColumn,
                items: dataset.columns.map((c) => c.name).toList(),
                onChanged: (value) => onChanged(state.copyWith(xColumn: value)),
              ),
              const SizedBox(height: 12),
              buildDropdown<String>(
                label: 'Y ось',
                initialValue: state.yColumn,
                items: dataset.columns.map((c) => c.name).toList(),
                onChanged: (value) => onChanged(state.copyWith(yColumn: value)),
              ),
            ],
          ),
        ),

        // Агрегация (только если Y числовая)
        if (state.yColumn != null && _isNumericColumn(dataset, state.yColumn))
          buildSection(
            title: Text('Метрика', style: TextStyle(fontSize: 14)),
            child: buildDropdown<AggregationType>(
              label: 'Агрегация',
              initialValue: state.aggregationType,
              items: AggregationType.values,
              onChanged: (value) => onChanged(state.copyWith(aggregationType: value!)),
              displayName: (type) => _aggregationName(type),
            ),
          ),
      ],

      // Нормализация
      buildSection(
        title: Text('Нормализация', style: TextStyle(fontSize: 14)),
        child: buildDropdown<NormalizeMode>(
          label: 'Тип',
          initialValue: state.normalizeMode,
          items: NormalizeMode.values,
          onChanged: (value) => onChanged(state.copyWith(normalizeMode: value!)),
          displayName: (mode) => _normalizeModeName(mode),
        ),
      ),

      // Сортировка
      buildSection(
        title: Text('Сортировка'),
        child: Column(
          children: [
            buildDropdown<SortMode>(
              label: 'По X',
              initialValue: state.sortX,
              items: SortMode.values,
              onChanged: (value) => onChanged(state.copyWith(sortX: value!)),
              displayName: (mode) => _sortModeName(mode),
            ),
            const SizedBox(height: 12),
            buildDropdown<SortMode>(
              label: 'По Y',
              initialValue: state.sortY,
              items: SortMode.values,
              onChanged: (value) => onChanged(state.copyWith(sortY: value!)),
              displayName: (mode) => _sortModeName(mode),
            ),
          ],
        ),
      ),

      // Проценты
      buildSection(
        title: Text(
          'Проценты',
          style: TextStyle(fontSize: 14),
        ),
        child: buildDropdown<PercentageMode>(
          label: 'Режим',
          initialValue: state.percentageMode,
          items: PercentageMode.values,
          onChanged: (value) => onChanged(state.copyWith(percentageMode: value!)),
          displayName: (mode) => _percentageModeName(mode),
        ),
      ),

      // Цвет
      buildSection(
        title: Text('Цвет', style: TextStyle(fontSize: 14)),
        child: Column(
          children: [
            buildDropdown<HeatmapPalette>(
              label: 'Палитра',
              initialValue: state.palette,
              items: HeatmapPalette.values,
              onChanged: (value) => onChanged(state.copyWith(palette: value!)),
              displayName: (p) => p.name,
            ),
            const SizedBox(height: 12),
            buildDropdown<HeatmapColorMode>(
              label: 'Режим раскраски',
              initialValue: state.colorMode,
              items: HeatmapColorMode.values,
              onChanged: (value) => onChanged(state.copyWith(colorMode: value!)),
              displayName: (mode) => mode == HeatmapColorMode.discrete ? 'Дискретный' : 'Градиент',
            ),
            if (state.colorMode == HeatmapColorMode.discrete) ...[
              const SizedBox(height: 12),
              buildDropdown<int>(
                label: 'Сегментов',
                initialValue: state.segments,
                items: const [5, 10, 20],
                onChanged: (value) => onChanged(state.copyWith(segments: value!)),
                displayName: (seg) => '$seg сегментов',
              ),
            ],
          ],
        ),
      ),

      // Отображение
      buildSection(
        title: Text('Отображение', style: TextStyle(fontSize: 14)),
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text('Подписи осей'),
              value: state.showAxisLabels,
              onChanged: (value) => onChanged(state.copyWith(showAxisLabels: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Значения в ячейках'),
              value: state.showValues,
              onChanged: (value) => onChanged(state.copyWith(showValues: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Только верхний треугольник'),
              value: state.triangleMode,
              onChanged: (value) => onChanged(state.copyWith(triangleMode: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Кластеризация'),
              value: state.clusterEnabled,
              onChanged: (value) => onChanged(state.copyWith(clusterEnabled: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ];
  }



  /// Возвращает локализованное название типа агрегации.
  static String _aggregationName(AggregationType type) {
    switch (type) {
      case AggregationType.count: return 'Количество';
      case AggregationType.sum: return 'Сумма';
      case AggregationType.avg: return 'Среднее';
      case AggregationType.min: return 'Минимум';
      case AggregationType.max: return 'Максимум';
      case AggregationType.median: return 'Медиана';
    }
  }

  /// Возвращает локализованное название режима нормализации.
  static String _normalizeModeName(NormalizeMode mode) {
    switch (mode) {
      case NormalizeMode.none: return 'Нет';
      case NormalizeMode.row: return 'По строкам';
      case NormalizeMode.column: return 'По столбцам';
      case NormalizeMode.total: return 'Общая';
    }
  }

  /// Возвращает локализованное название режима сортировки.
  static String _sortModeName(SortMode mode) {
    switch (mode) {
      case SortMode.none: return 'Нет';
      case SortMode.alphabetic: return 'По алфавиту';
      case SortMode.byValueAsc: return 'По возрастанию';
      case SortMode.byValueDesc: return 'По убыванию';
    }
  }

  /// Возвращает локализованное название режима процентов.
  static String _percentageModeName(PercentageMode mode) {
    switch (mode) {
      case PercentageMode.none: return 'Нет';
      case PercentageMode.row: return 'От строки';
      case PercentageMode.column: return 'От столбца';
      case PercentageMode.total: return 'От итога';
    }
  }

  /// Проверяет, является ли колонка числовой.
  static bool _isNumericColumn(Dataset dataset, String? columnName) {
    if (columnName == null) return false;
    final col = dataset.column(columnName);
    return col is NumericColumn;
  }
}