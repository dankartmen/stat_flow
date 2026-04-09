import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import '../../../core/theme/controls_style.dart';
import 'boxplot_state.dart';

/// {@template boxplot_controls}
/// Фабрика для создания элементов управления ящика с усами (box plot)
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением ящика с усами:
/// - Выбор числовой колонки для анализа
/// - Включение отображения среднего
/// - Включение отображения выбросов
/// - Ограничение числа точек для рендеринга
/// - Настройка визуального стиля (ширина, отступы, режим расчёта)
/// - Включение отображения всех точек с джиттером
/// 
/// {@endtemplate}
class BoxPlotControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [dataset] — датасет с данными для анализа
  /// - [state] — текущее состояние ящика с усами
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  static List<Widget> build({
    required BuildContext context,
    required Dataset dataset,
    required BoxPlotState state,
    required ValueChanged<BoxPlotState> onChanged,
  }) {
    final numericColumns = dataset.numericColumns;
    final theme = Theme.of(context);

    return [
      const SizedBox(height: 8),

      // Выбор колонки для ящика с усами
      buildSection(
        context: context,
        title: 'Колонка',
        icon: Icons.candlestick_chart_rounded,
        child: buildDropdown<String>(
          context: context,
          label: 'Числовая колонка',
          initialValue: state.columnName,
          items: numericColumns.map((c) => c.name).toList(),
          onChanged: (value) => onChanged(state.copyWith(columnName: value)),
        ),
      ),

      // Основные настройки
      buildSection(
        context: context,
        title: 'Основные настройки',
        icon: Icons.tune_rounded,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Показывать среднее'),
              value: state.showMean,
              onChanged: (v) => onChanged(state.copyWith(showMean: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: theme.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Показывать выбросы'),
              value: state.showOutliers,
              onChanged: (v) => onChanged(state.copyWith(showOutliers: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: theme.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Показывать все точки (джиттер)'),
              value: state.showAllPoints,
              onChanged: (v) => onChanged(state.copyWith(showAllPoints: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: theme.primaryColor,
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
            // Ширина ящика
            const Text('Ширина ящика', style: TextStyle(fontSize: 15)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.boxWidth,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: (v) => onChanged(state.copyWith(boxWidth: v)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    state.boxWidth.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Режим box plot
            buildDropdown<BoxPlotMode>(
              context: context,
              label: 'Режим расчёта',
              initialValue: state.boxPlotMode,
              items: BoxPlotMode.values,
              onChanged: (value) => onChanged(state.copyWith(boxPlotMode: value!)),
              displayName: (mode) => mode == BoxPlotMode.normal
                  ? 'Обычный'
                  : mode == BoxPlotMode.exclusive
                      ? 'Исключительный'
                      : 'Включающий',
            ),

            const SizedBox(height: 16),

            // Толщина границы
            Row(
              children: [
                const Text('Толщина границы'),
                const Spacer(),
                Text(state.borderWidth.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: state.borderWidth,
              min: 0,
              max: 6,
              divisions: 12,
              onChanged: (v) => onChanged(state.copyWith(borderWidth: v)),
            ),

            const SizedBox(height: 16),

            // Размер выбросов
            Row(
              children: [
                const Text('Размер выбросов'),
                const Spacer(),
                Text(state.outlierSize.toStringAsFixed(0)),
              ],
            ),
            Slider(
              value: state.outlierSize,
              min: 3,
              max: 14,
              divisions: 11,
              onChanged: (v) => onChanged(state.copyWith(outlierSize: v)),
            ),
          ],
        ),
      ),

      // Производительность
      buildSection(
        context: context,
        title: 'Производительность',
        icon: Icons.speed_rounded,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Максимум точек'),
                const Spacer(),
                Text(state.maxPoints > 0 ? '${state.maxPoints}' : 'Все'),
              ],
            ),
            Slider(
              value: state.maxPoints.toDouble().clamp(1000, 20000),
              min: 1000,
              max: 20000,
              divisions: 19,
              onChanged: (v) => onChanged(state.copyWith(maxPoints: v.toInt())),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Кнопка сброса
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: OutlinedButton.icon(
          onPressed: () => onChanged(BoxPlotState()),
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