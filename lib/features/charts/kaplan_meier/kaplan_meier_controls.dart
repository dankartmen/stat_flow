import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import '../../../core/theme/controls_style.dart';
import 'kaplan_meier_state.dart';

/// {@template kaplan_meier_controls}
/// Фабрика для создания элементов управления кривой выживаемости Каплан-Мейера.
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением кривой выживаемости:
/// - Выбор колонки времени (числовая)
/// - Выбор колонки события (категориальная/текстовая с бинарным значением)
/// - Группировка по категориальной колонке (для сравнения групп)
/// - Настройка отображения (показывать цензурированные наблюдения, толщина линии)
/// 
/// Автоматически отображает секцию группировки только после выбора колонок.
/// {@endtemplate}
class KaplanMeierControls {
  /// Строит список виджетов управления на основе состояния.
  ///
  /// Принимает:
  /// - [context] — контекст сборки для доступа к теме
  /// - [dataset] — датасет с данными
  /// - [state] — текущее состояние кривой Каплан-Мейера
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - список виджетов для размещения в панели управления
  static List<Widget> build({
    required BuildContext context,
    required Dataset dataset,
    required KaplanMeierState state,
    required ValueChanged<KaplanMeierState> onChanged,
  }) {
    final numericColumns = dataset.numericColumns;
    final categoricalColumns = dataset.columns
        .where((c) => c is CategoricalColumn || c is TextColumn)
        .map((c) => c.name)
        .toList();
    final theme = Theme.of(context);

    return [
      const SizedBox(height: 8),

      // Секция выбора основных колонок
      buildSection(
        context: context,
        title: 'Данные',
        icon: Icons.timeline,
        child: Column(
          children: [
            buildDropdown<String>(
              context: context,
              label: 'Колонка времени',
              initialValue: state.timeColumn,
              items: numericColumns.map((c) => c.name).toList(),
              onChanged: (value) => onChanged(state.copyWith(timeColumn: value)),
            ),
            const SizedBox(height: 12),
            buildDropdown<String>(
              context: context,
              label: 'Колонка события',
              initialValue: state.eventColumn,
              items: categoricalColumns,
              onChanged: (value) => onChanged(state.copyWith(eventColumn: value)),
            ),
          ],
        ),
      ),

      // Секция группировки (показывается только если выбраны основные колонки)
      if (state.timeColumn != null && state.eventColumn != null)
        buildSection(
          context: context,
          title: 'Группировка',
          icon: Icons.group_work,
          child: buildDropdown<String>(
            context: context,
            label: 'Сравнить группы',
            initialValue: state.groupByColumn,
            items: categoricalColumns,
            nullable: true,
            onChanged: (value) => onChanged(state.copyWith(groupByColumn: value)),
          ),
        ),

      // Секция визуальных настроек
      buildSection(
        context: context,
        title: 'Настройки',
        icon: Icons.tune,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Показывать цензурированные наблюдения'),
              value: state.showCensoredMarks,
              onChanged: (v) => onChanged(state.copyWith(showCensoredMarks: v)),
              activeThumbColor: theme.primaryColor,
            ),
            Row(
              children: [
                const Text('Толщина линии'),
                const Spacer(),
                Text(state.lineWidth.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: state.lineWidth,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              onChanged: (v) => onChanged(state.copyWith(lineWidth: v)),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),
      // Кнопка сброса
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: OutlinedButton.icon(
          onPressed: () => onChanged(KaplanMeierState()),
          icon: const Icon(Icons.refresh),
          label: const Text('Сбросить'),
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