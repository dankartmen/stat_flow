import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import '../../../core/theme/controls_style.dart';
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
  /// - [context] — контекст для доступа к теме и локализации
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required Dataset dataset,
    required HistogramState state,
    required ValueChanged<HistogramState> onChanged,
    required BuildContext context,
  }) {
    final numericColumns = dataset.numericColumns;
    final theme = Theme.of(context);
    final activeThumbColor = theme.colorScheme.primary;

    // Колонки, доступные для разделения (категориальные и текстовые)
    final splitColumns = dataset.columns
        .where((c) => c is CategoricalColumn || c is TextColumn)
        .map((c) => c.name)
        .toList();

    return [
      const SizedBox(height: 8),

      // 1. Выбор колонки
      buildSection(
        context: context,
        title: 'Колонка',
        icon: Icons.bar_chart_rounded,
        child: buildDropdown<String>(
          context: context,
          label: 'Числовая колонка',
          initialValue: state.columnName,
          items: numericColumns.map((c) => c.name).toList(),
          onChanged: (value) {
            var newState = state.copyWith(columnName: value);
            // Если сбрасываем колонку, сбрасываем и split
            if (value == null) {
              newState = newState.resetSplitBy();
            }
            onChanged(newState);
          },
        ),
      ),

      // Разделение по категориальной переменной
      if (state.columnName != null && splitColumns.isNotEmpty)
        buildSection(
          context: context,
          title: 'Разделение',
          icon: Icons.call_split_rounded,
          child: buildDropdown<String>(
            context: context,
            label: 'Группировать по',
            initialValue: state.splitByColumn,
            items: splitColumns,
            nullable: true,
            onChanged: (value) {
              if (value == null) {
                onChanged(state.resetSplitBy());
              } else {
                onChanged(state.copyWith(splitByColumn: value));
              }
            },
          ),
        ),

      // Основные настройки (количество корзин, кривая и т.д.)
      buildSection(
        context: context,
        title: 'Основные настройки',
        icon: Icons.tune_rounded,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Количество корзин'),
                const Spacer(),
                Text(state.bins.toString()),
              ],
            ),
            Slider(
              value: state.bins.toDouble(),
              min: 5,
              max: 50,
              divisions: 45,
              onChanged: (v) => onChanged(state.copyWith(bins: v.toInt())),
            ),
            SwitchListTile(
              title: const Text('Кривая нормального распределения'),
              value: state.showNormalDistributionCurve,
              onChanged: (v) => onChanged(state.copyWith(showNormalDistributionCurve: v)),
              activeThumbColor: theme.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Показывать значения'),
              value: state.showDataLabels,
              onChanged: (v) => onChanged(state.copyWith(showDataLabels: v)),
              activeThumbColor: theme.primaryColor,
            ),
          ],
        ),
      ),

      // Внешний вид
      buildSection(
        context: context,
        title: 'Внешний вид',
        icon: Icons.format_paint_rounded,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Толщина границы'),
                const Spacer(),
                Text(state.borderWidth.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: state.borderWidth,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              onChanged: (v) => onChanged(state.copyWith(borderWidth: v)),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Кнопка сброса
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: OutlinedButton.icon(
          onPressed: () => onChanged(HistogramState()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Сбросить настройки'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 32),
    ];
  }
}