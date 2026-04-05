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
class ContextPanel extends ConsumerStatefulWidget {
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
  ConsumerState<ContextPanel> createState() => _ContextPanelState();
}

class _ContextPanelState extends ConsumerState<ContextPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDatasetLoaded = widget.dataset != null;

    // Если датасет не загружен — показываем сообщение и кнопку загрузки (дублируем)
    if (!isDatasetLoaded) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 280 : 48,
        color: Colors.grey[100],
        child: _isExpanded
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Датасет не загружен'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(datasetProvider.notifier).state = null,
                      child: const Text('Загрузить датасет'),
                    ),
                  ],
                ),
              )
            : _buildCollapsedButton(),
      );
    }

    // Если датасет загружен, но нет выбранного графика — показываем кнопку создания
    if (widget.selectedChart == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 280 : 48,
        color: Colors.grey[100],
        child: _isExpanded
            ? Column(
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
              )
            : _buildCollapsedButton(),
      );
    }

    // Есть выбранный график — показываем его настройки через плагин
    final plugin = ChartRegistry.get(widget.selectedChart!.type);
    final controls = plugin.buildControls(widget.selectedChart!, () {}, ref);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? 280 : 48,
      color: Colors.grey[100],
      child: _isExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Настройки: ${widget.selectedChart!.type.name}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        icon: Icon(
                          Icons.chevron_left,
                          color: Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                        tooltip: 'Свернуть',
                      ),
                    ],
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
            )
          : _buildCollapsedButton(),
    );
  }

  /// Строит кнопку для разворачивания панели (свернутое состояние)
  Widget _buildCollapsedButton() {
    return SizedBox(
      width: 48,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = true;
              });
            },
            icon: Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 24,
            ),
            tooltip: 'Развернуть панель',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 8),
          const RotatedBox(
            quarterTurns: 1,
            child: Text(
              'Настройки',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
          onTap: () => widget.onAddChart(type),
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