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
          onChanged: (value) => onChanged(state.copyWith(columnName: value)),
        ),
      ),

      // 2. Количество корзин + интервал
      buildSection(
        context: context,
        title: 'Корзины и интервал',
        icon: Icons.grid_on_rounded,
        child: Column(
          children: [
            // Слайдер количества корзин
            Row(
              children: [
                const Text('Количество корзин', style: TextStyle(fontSize: 15)),
                const Spacer(),
                Text(
                  state.bins.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Slider(
              value: state.bins.toDouble(),
              min: 5,
              max: 50,
              divisions: 45,
              label: state.bins.toString(),
              onChanged: (v) => onChanged(state.copyWith(bins: v.toInt())),
            ),

            const SizedBox(height: 16),

            // Прямое управление интервалом (опционально)
            buildDropdown<double?>(
              context: context,
              label: 'Интервал корзины (binInterval)',
              initialValue: state.binInterval,
              items: const [5.0, 10.0, 20.0, 50.0],
              onChanged: (value) => onChanged(state.copyWith(binInterval: value)),
              displayName: (v) => v == null ? 'Авто' : v.toStringAsFixed(1),
            ),
          ],
        ),
      ),

      // 3. Внешний вид
      buildSection(
        context: context,
        title: 'Внешний вид',
        icon: Icons.format_paint_rounded,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Кривая нормального распределения'),
              value: state.showNormalDistributionCurve,
              onChanged: (v) => onChanged(state.copyWith(showNormalDistributionCurve: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile(
              title: const Text('Подписи значений'),
              value: state.showDataLabels,
              onChanged: (v) => onChanged(state.copyWith(showDataLabels: v)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
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
              label: state.borderWidth.toStringAsFixed(1),
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