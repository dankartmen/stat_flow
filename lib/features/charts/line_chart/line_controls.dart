import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import '../../../core/theme/controls_style.dart';
import 'line_state.dart';

/// {@template line_controls}
/// Фабрика для создания элементов управления линейным графиком
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением линейного графика:
/// - Выбор числовой колонки для оси Y
/// - Включение/отключение маркеров
/// - Включение/отключение сглаживания (если есть)
/// - Включение/отключение сетки
/// - Настройка стиля линии (толщина, пунктир)
/// - Включение современных фич (трендлайн, trackball, анимация)
/// 
/// {@endtemplate}
class LineControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние диаграммы рассеяния
  /// - [onChanged] — колбэк для обновления состояния
  /// - [context] — контекст для доступа к теме и локализации
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required BuildContext context,
    required Dataset dataset,
    required LineState state,
    required ValueChanged<LineState> onChanged,
  }) {
    final suitableColumns = dataset.columns
        .where((c) => c is NumericColumn || c is DateTimeColumn)
        .map((c) => c.name)
        .toList();

    return [
      const SizedBox(height: 8),

      // 1. Колонка
      buildSection(
        context: context,
        title: 'Колонка',
        icon: Icons.show_chart_rounded,
        child: buildDropdown<String>(
          context: context,
          label: 'Ось Y (значения)',
          initialValue: state.columnName,
          items: suitableColumns,
          onChanged: (value) => onChanged(state.copyWith(columnName: value)),
        ),
      ),

      // 2. Основные настройки
      buildSection(
        context: context,
        title: 'Основные настройки',
        icon: Icons.tune_rounded,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Сетка'),
              value: state.showGridLines,
              onChanged: (v) => onChanged(state.copyWith(showGridLines: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            SwitchListTile(
              title: const Text('Анимация'),
              value: state.animationEnabled,
              onChanged: (v) => onChanged(state.copyWith(animationEnabled: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ),

      // 3. Стиль линии
      buildSection(
        context: context,
        title: 'Стиль линии',
        icon: Icons.line_style_rounded,
        child: Column(
          children: [
            // Тип линии
            buildDropdown<LineType>(
              context: context,
              label: 'Тип линии',
              initialValue: state.lineType,
              items: LineType.values,
              onChanged: (value) => onChanged(state.copyWith(lineType: value!)),
              displayName: (type) => type == LineType.straight
                  ? 'Прямая'
                  : type == LineType.curved
                      ? 'Сглаженная'
                      : 'Ступенчатая',
            ),
            const SizedBox(height: 16),

            // Толщина линии
            Row(
              children: [
                const Text('Толщина линии'),
                const Spacer(),
                Text(state.lineWidth.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: state.lineWidth,
              min: 1,
              max: 8,
              divisions: 14,
              onChanged: (v) => onChanged(state.copyWith(lineWidth: v)),
            ),
            const SizedBox(height: 12),

            // Пунктир
            SwitchListTile(
              title: const Text('Пунктирная линия'),
              value: state.isDashed,
              onChanged: (v) => onChanged(state.copyWith(isDashed: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ),

      // 4. Маркеры и подписи
      buildSection(
        context: context,
        title: 'Маркеры и подписи',
        icon: Icons.circle_outlined,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Маркеры на точках'),
              value: state.showMarkers,
              onChanged: (v) => onChanged(state.copyWith(showMarkers: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Размер маркеров'),
                const Spacer(),
                Text(state.markerSize.toStringAsFixed(0)),
              ],
            ),
            Slider(
              value: state.markerSize,
              min: 3,
              max: 12,
              divisions: 9,
              onChanged: (v) => onChanged(state.copyWith(markerSize: v)),
            ),
            SwitchListTile(
              title: const Text('Подписи значений'),
              value: state.showDataLabels,
              onChanged: (v) => onChanged(state.copyWith(showDataLabels: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ),

      // 5. Дополнительно
      buildSection(
        context: context,
        title: 'Дополнительно',
        icon: Icons.analytics_rounded,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Трендлайн'),
              value: state.showTrendline,
              onChanged: (v) => onChanged(state.copyWith(showTrendline: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            SwitchListTile(
              title: const Text('Trackball (подсветка)'),
              value: state.trackballEnabled,
              onChanged: (v) => onChanged(state.copyWith(trackballEnabled: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Кнопка сброса
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: OutlinedButton.icon(
          onPressed: () => onChanged(LineState()),
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