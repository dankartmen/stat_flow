import 'dart:developer';

import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import '../../../core/theme/controls_style.dart';
import 'bar_state.dart';

/// {@template bar_controls}
/// Фабрика для создания элементов управления столбчатой диаграммой.
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением столбчатой диаграммы:
/// - Выбор колонки для анализа (числовая, категориальная или текстовая)
/// - Настройка ширины столбцов
/// - Включение отображения значений над столбцами
/// - Настройка внешнего вида (закругление, отступы, трек)
/// - Дополнительные настройки для числовых колонок (гистограмма)
/// - Дополнительные настройки для категориальных/текстовых колонок (макс. категории, сортировка) 
/// {@endtemplate}
class BarControls {
  /// Строит список виджетов управления на основе состояния.
  ///
  /// Принимает:
  /// - [context] — контекст сборки
  /// - [dataset] — датасет с данными
  /// - [state] — текущее состояние диаграммы
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - список виджетов для панели управления
  static List<Widget> build({
    required BuildContext context,
    required Dataset dataset,
    required BarState state,
    required ValueChanged<BarState> onChanged,
  }) {
    final suitableColumns = dataset.columns
        .where((c) => c is NumericColumn || c is CategoricalColumn || c is TextColumn)
        .map((c) => c.name)
        .toList();
    final theme = Theme.of(context);

    // Определяем, можно ли группировать по выбранной колонке
    final mainColumn = state.columnName != null ? dataset.column(state.columnName!) : null;
    final canGroup = mainColumn is CategoricalColumn || mainColumn is TextColumn;

    // Колонки, доступные для группировки (только категориальные и текстовые)
    final groupingColumns = dataset.columns
        .where((c) => c is CategoricalColumn || c is TextColumn)
        .map((c) => c.name)
        .toList();

    return [
      const SizedBox(height: 8),

      // Выбор колонки
      buildSection(
        context: context,
        title: 'Колонка',
        icon: Icons.bar_chart_rounded,
        child: buildDropdown<String>(
          context: context,
          label: 'Выбрать колонку',
          initialValue: state.columnName,
          items: suitableColumns,
          onChanged: (value) {
            log('[BarControls] columnName changed to $value, current state: columnName=${state.columnName}, groupByColumn=${state.groupByColumn}');
            var newState = state.copyWith(columnName: value);
            if (value != null) {
              final col = dataset.column(value);
              if (col is NumericColumn) {
                log('[BarControls] selected column is NumericColumn -> resetting groupByColumn');
                newState = newState.resetGroupBy();
              }
            }
            log('[BarControls] calling onChanged with state: columnName=${newState.columnName}, groupByColumn=${newState.groupByColumn}');
            onChanged(newState);
          },
        ),
      ),

      // Группировка (только если текущая колонка допускает)
      if (canGroup && groupingColumns.isNotEmpty)
        buildSection(
          context: context,
          title: 'Группировка',
          icon: Icons.group_work_rounded,
          child: Column(
            children: [
              buildDropdown<String>(
                context: context,
                label: 'Группировать по',
                initialValue: state.groupByColumn,
                items: groupingColumns,
                onChanged: (value) => onChanged(state.copyWith(groupByColumn: value)),
              ),
              if (state.groupByColumn != null) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Составные столбцы (stacked)'),
                  value: state.stacked,
                  onChanged: (v) => onChanged(state.copyWith(stacked: v)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
        
      buildSection(
        context: context,
        title: 'Основные настройки',
        icon: Icons.tune_rounded,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Показывать значения'),
              value: state.showValues,
              onChanged: (v) => onChanged(state.copyWith(showValues: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeThumbColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Ширина столбцов'),
                const Spacer(),
                Text(state.barWidth.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: state.barWidth,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (v) => onChanged(state.copyWith(barWidth: v)),
            ),
          ],
        ),
      ),

      buildSection(
        context: context,
        title: 'Внешний вид',
        icon: Icons.format_paint_rounded,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Закругление углов'),
                const Spacer(),
                Text('${state.borderRadius.toInt()}'),
              ],
            ),
            Slider(
              value: state.borderRadius,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (v) => onChanged(state.copyWith(borderRadius: v)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Показывать трек (фон)'),
              value: state.showTrack,
              onChanged: (v) => onChanged(state.copyWith(showTrack: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeThumbColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text('Расстояние между столбцами', style: TextStyle(fontSize: 15)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.spacing,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    onChanged: (v) => onChanged(state.copyWith(spacing: v)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    state.spacing.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Дополнительные настройки для числовых колонок (гистограмма)
      if (state.columnName != null && dataset.column(state.columnName!) is NumericColumn)
        buildSection(
          context: context,
          title: 'Гистограмма (числовые данные)',
          icon: Icons.grid_on_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Количество корзин'),
                  const Spacer(),
                  Text(state.binCount.toString()),
                ],
              ),
              Slider(
                value: state.binCount.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                onChanged: (v) => onChanged(state.copyWith(binCount: v.toInt())),
              ),
            ],
          ),
        ),

      // Дополнительные настройки для категориальных/текстовых колонок
      if (state.columnName != null &&
          (dataset.column(state.columnName!) is CategoricalColumn ||
           dataset.column(state.columnName!) is TextColumn))
        buildSection(
          context: context,
          title: 'Категории',
          icon: Icons.category_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Максимум категорий'),
                  const Spacer(),
                  Text(state.maxCategories.toString()),
                ],
              ),
              Slider(
                value: state.maxCategories.toDouble(),
                min: 5,
                max: 40,
                divisions: 35,
                onChanged: (v) => onChanged(state.copyWith(maxCategories: v.toInt())),
              ),
              SwitchListTile(
                title: const Text('Сортировка по убыванию'),
                value: state.sortDescending,
                onChanged: (v) => onChanged(state.copyWith(sortDescending: v)),
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),

      const SizedBox(height: 24),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: OutlinedButton.icon(
          onPressed: () => onChanged(BarState()),
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