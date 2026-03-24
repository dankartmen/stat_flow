import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dataset/dataset.dart';
import '../../core/providers/providers.dart';

import '../charts/chart_registry.dart';
import '../charts/chart_state.dart';
import '../charts/chart_type.dart';
import '../charts/floating_chart/floating_chart_data.dart';

/// {@template context_panel}
/// Контекстная панель для настройки графиков и управления датасетом
///
/// Отображает контекстные элементы управления в зависимости от состояния:
/// - Если датасет не загружен: показывает сообщение и кнопку загрузки
/// - Если датасет загружен, но график не выбран: показывает кнопку создания графика
/// - Если выбран график: отображает настройки этого графика через соответствующий плагин
///
/// Используется для предоставления быстрого доступа к настройкам текущего графика.
/// {@endtemplate}
class ContextPanel extends ConsumerWidget {
  /// Текущий загруженный датасет (может быть null)
  final Dataset? dataset;

  /// Выбранный в данный момент график (может быть null)
  final FloatingChartData? selectedChart;

  /// Коллбек для создания нового графика указанного типа
  final void Function(ChartType) onAddChart;

  /// Коллбек для создания графика для конкретного поля датасета
  final void Function(String, ChartType) onCreateChartForField;

  /// Коллбек для обновления состояния графика (после изменения настроек)
  final void Function(int, ChartState) onUpdateChartState;

  /// {@macro context_panel}
  const ContextPanel({
    super.key,
    required this.dataset,
    required this.selectedChart,
    required this.onAddChart,
    required this.onCreateChartForField,
    required this.onUpdateChartState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDatasetLoaded = dataset != null;

    // Если датасет не загружен — показываем сообщение и кнопку загрузки (дублируем)
    if (!isDatasetLoaded) {
      return Container(
        width: 280,
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Датасет не загружен'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(datasetProvider.notifier).state = null, // загрузить
                child: const Text('Загрузить датасет'),
              ),
            ],
          ),
        ),
      );
    }

    // Если датасет загружен, но нет выбранного графика — показываем кнопку создания
    if (selectedChart == null) {
      return Container(
        width: 280,
        color: Colors.grey[100],
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Нет выбранного графика',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showChartMenu(context),
              child: const Text('Создать график'),
            ),
          ],
        ),
      );
    }

    // Есть выбранный график — показываем его настройки через плагин
    final plugin = ChartRegistry.get(selectedChart!.type);
    final controls = plugin.buildControls(selectedChart!, () {}, ref); // refresh пока не нужен, т.к. обновляем через onUpdateChartState

    // Обернём в ListView с возможностью скролла
    return Container(
      width: 280,
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Настройки: ${selectedChart!.type.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: controls,
            ),
          ),
        ],
      ),
    );
  }

  /// Отображает всплывающее меню с доступными типами графиков
  void _showChartMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(80, 200, 0, 0),
      items: ChartType.values.map((type) {
        return PopupMenuItem(
          onTap: () => onAddChart(type),
          child: Row(
            children: [
              Icon(_iconForType(type), size: 20),
              const SizedBox(width: 12),
              Text(type.name),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Возвращает иконку для указанного типа графика
  IconData _iconForType(ChartType type) {
    switch (type) {
      case ChartType.heatmap:
        return Icons.heat_pump;
      case ChartType.scatter:
        return Icons.bubble_chart;
      case ChartType.histogram:
        return Icons.bar_chart;
      case ChartType.boxplot:
        return Icons.candlestick_chart;
      case ChartType.linechart:
        return Icons.line_axis;
      case ChartType.barchart:
        return Icons.bar_chart;
    }
  }
}