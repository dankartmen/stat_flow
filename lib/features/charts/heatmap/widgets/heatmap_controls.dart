import 'package:flutter/material.dart';
import 'package:heatmap_canvas/heatmap.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import '../../../../core/theme/controls_style.dart';
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
    required BuildContext context,
  }) {
    final isCorrelationMode = state.useCorrelation;

    return [
      // Режим (корреляция / оси)
      buildSection(
        context: context,
        title: 'Режим',
        icon: Icons.tune_rounded,
        child: SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Корреляция', style: TextStyle(overflow: TextOverflow.ellipsis),),
                  icon: Icon(Icons.show_chart_rounded, size: 18,),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Оси', style: TextStyle(overflow: TextOverflow.ellipsis),),
                  icon: Icon(Icons.swap_horiz_rounded, size: 18,),
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
        ),
      ),

      // Выбор осей (только если не корреляция)
      if (!isCorrelationMode) ...[
        buildSection(
          context: context,
          title: 'Оси',
          icon: Icons.swap_horiz_rounded,
          initiallyExpanded: true,
          child: Column(
            children: [
              buildDropdown<String>(
                context: context,
                label: 'X ось',
                initialValue: state.xColumn,
                items: dataset.columns.map((c) => c.name).toList(),
                onChanged: (value) => onChanged(state.copyWith(xColumn: value)),
              ),
              const SizedBox(height: 20),
              buildDropdown<String>(
                context: context,
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
            context: context,
            title: 'Метрика',
            icon: Icons.functions_rounded,
            child: buildDropdown<AggregationType>(
              context: context,
              label: 'Агрегация',
              initialValue: state.aggregationType,
              items: AggregationType.values,
              onChanged: (value) => onChanged(state.copyWith(aggregationType: value!)),
              displayName: _aggregationName,
            ),
          ),
      ],

      // Нормализация
      buildSection(
        context: context,
        title: 'Нормализация',
        icon: Icons.scale_rounded,
        child: buildDropdown<NormalizeMode>(
          context: context,
          label: 'Тип нормализации',
          initialValue: state.normalizeMode,
          items: NormalizeMode.values,
          onChanged: (value) => onChanged(state.copyWith(normalizeMode: value!)),
          displayName: _normalizeModeName,
        ),
      ),

      // Сортировка
      buildSection(
        context: context,
        title: 'Сортировка',
        icon: Icons.sort_rounded,
        child: Column(
          children: [
            buildDropdown<SortMode>(
              context: context,
              label: 'По X (строки)',
              initialValue: state.sortX,
              items: SortMode.values,
              onChanged: (value) => onChanged(state.copyWith(sortX: value!)),
              displayName: _sortModeName,
            ),
            const SizedBox(height: 20),
            buildDropdown<SortMode>(
              context: context,
              label: 'По Y (столбцы)',
              initialValue: state.sortY,
              items: SortMode.values,
              onChanged: (value) => onChanged(state.copyWith(sortY: value!)),
              displayName: _sortModeName,
            ),
          ],
        ),
      ),

      // Проценты
      buildSection(
        context: context,
        title: 'Проценты',
        icon: Icons.percent_rounded,
        child: buildDropdown<PercentageMode>(
          context: context,
          label: 'Режим процентов',
          initialValue: state.percentageMode,
          items: PercentageMode.values,
          onChanged: (value) => onChanged(state.copyWith(percentageMode: value!)),
          displayName: _percentageModeName,
        ),
      ),

      // Цвет
      buildSection(
        context: context,
        title: 'Цветовая схема',
        icon: Icons.palette_rounded,
        child: Column(
          children: [
            buildDropdown<HeatmapPalette>(
              context: context,
              label: 'Палитра',
              initialValue: state.palette,
              items: HeatmapPalette.values,
              onChanged: (value) => onChanged(state.copyWith(palette: value!)),
              displayName: (p) => p.name,
            ),
            const SizedBox(height: 20),
            buildDropdown<HeatmapColorMode>(
              context: context,
              label: 'Режим раскраски',
              initialValue: state.colorMode,
              items: HeatmapColorMode.values,
              onChanged: (value) => onChanged(state.copyWith(colorMode: value!)),
              displayName: (mode) => mode == HeatmapColorMode.discrete ? 'Дискретный' : 'Градиент',
            ),
            if (state.colorMode == HeatmapColorMode.discrete) ...[
              const SizedBox(height: 20),
              buildDropdown<int>(
                context: context,
                label: 'Количество сегментов',
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
        context: context,
        title: 'Отображение',
        icon: Icons.visibility_rounded,
        child: Column(
          children: [
            buildSwitch(context, 'Подписи осей', state.showAxisLabels,
                (v) => onChanged(state.copyWith(showAxisLabels: v))),
            buildSwitch(context, 'Значения в ячейках', state.showValues,
                (v) => onChanged(state.copyWith(showValues: v))),
            buildSwitch(context, 'Только верхний треугольник', state.triangleMode,
                (v) => onChanged(state.copyWith(triangleMode: v))),
            buildSwitch(context, 'Кластеризация', state.clusterEnabled,
                (v) => onChanged(state.copyWith(clusterEnabled: v))),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Кнопка сброса
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            onChanged(HeatmapState()); // сброс к дефолтным значениям
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Сбросить все настройки'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),

      const SizedBox(height: 32),
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