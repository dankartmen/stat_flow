import 'package:flutter/material.dart';
import '../../../core/dataset/dataset.dart';
import '../../../core/theme/controls_style.dart';
import 'pairplot_state.dart';

/// {@template pairplot_controls}
/// Фабрика для создания элементов управления Pair Plot (матрицей рассеяния).
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением матрицы рассеяния:
/// - Выбор колонок для включения в матрицу
/// - Настройка внешнего вида точек (размер, прозрачность)
/// - Настройка производительности (макс. колонок для тултипов, макс. точек)
/// - Включение/выключение отображения корреляции и гистограмм
/// {@endtemplate}
class PairPlotControls {
  /// Строит список виджетов управления на основе состояния.
  ///
  /// Принимает:
  /// - [context] — контекст сборки для доступа к теме
  /// - [dataset] — датасет с данными
  /// - [state] — текущее состояние Pair Plot
  /// - [onChanged] — колбэк для обновления состояния
  ///
  /// Возвращает:
  /// - список виджетов для размещения в панели управления
  static List<Widget> build({
    required BuildContext context,
    required Dataset dataset,
    required PairPlotState state,
    required ValueChanged<PairPlotState> onChanged,
  }) {
    final theme = Theme.of(context);
    final numericColumns = dataset.numericColumns.map((c) => c.name).toList();

    return [
      const SizedBox(height: 8),

      // Выбор колонок для отображения в матрице
      buildSection(
        context: context,
        title: 'Колонки',
        icon: Icons.view_column_rounded,
        child: Column(
          children: [
            const Text('Выберите колонки для матрицы (по умолчанию все)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: numericColumns.map((name) {
                final selected = state.selectedColumns == null ||
                    state.selectedColumns!.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (value) {
                    final newList = state.selectedColumns != null
                        ? List<String>.from(state.selectedColumns!)
                        : List<String>.from(numericColumns);
                    if (value) {
                      if (!newList.contains(name)) newList.add(name);
                    } else {
                      newList.remove(name);
                    }
                    onChanged(state.copyWith(selectedColumns: newList));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => onChanged(state.copyWith(selectedColumns: null)),
              child: const Text('Выбрать все'),
            ),
          ],
        ),
      ),

      // Настройки внешнего вида точек
      buildSection(
        context: context,
        title: 'Внешний вид',
        icon: Icons.format_paint_rounded,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Размер точек'),
                const Spacer(),
                Text('${state.pointSize.toInt()}'),
              ],
            ),
            Slider(
              value: state.pointSize,
              min: 1,
              max: 8,
              divisions: 7,
              onChanged: (v) => onChanged(state.copyWith(pointSize: v)),
            ),
            Row(
              children: [
                const Text('Прозрачность'),
                const Spacer(),
                Text(state.pointOpacity.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: state.pointOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (v) => onChanged(state.copyWith(pointOpacity: v)),
            ),
          ],
        ),
      ),
      
      // Настройки производительности
      buildSection(
        context: context,
        title: 'Производительность',
        icon: Icons.speed_rounded,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Отключить тултипы при кол-ве колонок >'),
                const Spacer(),
                Text('${state.maxColumnsForTooltips}'),
              ],
            ),
            Slider(
              value: state.maxColumnsForTooltips.toDouble(),
              min: 2,
              max: 12,
              divisions: 10,
              onChanged: (v) => onChanged(state.copyWith(maxColumnsForTooltips: v.toInt())),
            ),
          ],
        ),
      ),
      
      // Дополнительные настройки
      buildSection(
        context: context,
        title: 'Настройки',
        icon: Icons.tune_rounded,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Показывать корреляцию'),
              value: state.showCorrelation,
              onChanged: (v) => onChanged(state.copyWith(showCorrelation: v)),
              activeThumbColor: theme.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Гистограммы по диагонали'),
              value: state.showHistogramOnDiagonal,
              onChanged: (v) => onChanged(state.copyWith(showHistogramOnDiagonal: v)),
              activeThumbColor: theme.primaryColor,
            ),
            Row(
              children: [
                const Text('Макс. точек'),
                const Spacer(),
                Text(state.maxPoints > 0 ? '${state.maxPoints}' : 'Все'),
              ],
            ),
            Slider(
              value: state.maxPoints.toDouble().clamp(100, 5000),
              min: 100,
              max: 5000,
              divisions: 49,
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
          onPressed: () => onChanged(PairPlotState()),
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