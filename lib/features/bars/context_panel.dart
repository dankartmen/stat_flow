import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dataset/dataset.dart';
import '../../core/providers/providers.dart';
import '../charts/chart_registry.dart';
import '../charts/chart_state.dart';
import '../charts/chart_type.dart';
import '../charts/floating_chart/floating_chart_data.dart';
import '../table/widget/table_preview_screen.dart';

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


  /// Коллбек для обновления состояния графика (после изменения настроек)
  final void Function(int, ChartState) onUpdateChartState;

  const ContextPanel({
    super.key,
    required this.dataset,
    required this.selectedChart,
    required this.onAddChart,
    required this.onUpdateChartState,
  });

  @override
  ConsumerState<ContextPanel> createState() => _ContextPanelState();
}

class _ContextPanelState extends ConsumerState<ContextPanel> {
  bool _isExpanded = true;
  bool _showContent = true;
  
  void _togglePanel() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _showContent = false;        // сразу прячем контент при сворачивании
      } else {
        Future.delayed(const Duration(milliseconds: 280), () {
          if (mounted && _isExpanded) setState(() => _showContent = true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelWidth = _isExpanded ? 300.0 : 48.0;
    log('Building ContextPanel');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: panelWidth,
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.hardEdge,
      onEnd: () {
        if (_isExpanded) {
          setState(() => _showContent = true);
        }
      },
      child: _isExpanded && _showContent
          ? _ExpandedContent(
              dataset: widget.dataset,
              selectedChart: widget.selectedChart,
              onAddChart: widget.onAddChart,
              onUpdateChartState: widget.onUpdateChartState,
              onTogglePanel: _togglePanel,
            )
          : _CollapsedContent(onToggle: _togglePanel),
    );
  }
}

/// {@template expanded_content}
/// Контент для развернутого состояния панели
/// {@endtemplate}
class _ExpandedContent extends ConsumerWidget {
  /// Датасет для отображения (может быть null)
  final Dataset? dataset;
  /// Выбранный график для отображения настроек (может быть null)
  final FloatingChartData? selectedChart;
  /// Коллбек для создания нового графика указанного типа
  final void Function(ChartType) onAddChart;
  /// Коллбек для обновления состояния графика (после изменения настроек)
  final void Function(int, ChartState) onUpdateChartState;
  /// Коллбек для сворачивания панели
  final VoidCallback onTogglePanel;

  /// {@macro expanded_content}
  const _ExpandedContent({
    required this.dataset,
    required this.selectedChart,
    required this.onAddChart,
    required this.onUpdateChartState,
    required this.onTogglePanel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dataset == null) {
      return _NoDatasetContent();
    }
    if (selectedChart == null) {
      return _NoChartContent(onAddChart: onAddChart);
    }
    return _ChartSettingsContent(
      selectedChart: selectedChart!,
      onUpdateChartState: onUpdateChartState,
      onTogglePanel: onTogglePanel,
    );
  }
}


/// {@template no_dataset_content}
/// Контент для состояния, когда датасет не загружен
/// Показывает сообщение и кнопку для загрузки датасета
/// {@endtemplate}
class _NoDatasetContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Датасет не загружен', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TablePreviewScreen()),
                );
                if (result != null && result is Dataset && context.mounted) {
                  ref.read(datasetProvider.notifier).state = result;
                }
              },
              child: const Text('Загрузить датасет'),
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template no_chart_content}
/// Контент для состояния, когда график не выбран
/// Показывает сообщение и кнопку для создания нового графика
/// {@endtemplate}
class _NoChartContent extends StatelessWidget {
  /// Коллбек для создания нового графика указанного типа
  final void Function(ChartType) onAddChart;

  const _NoChartContent({required this.onAddChart});

  /// Показывает меню выбора типа графика при нажатии на кнопку "Создать график"
  void _showChartMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero),
          button.localToGlobal(button.size.bottomRight(Offset.zero)),
        ),
        Offset.zero & MediaQuery.sizeOf(context),
      ),
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

  /// Возвращает иконку для данного типа графика
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
        return Icons.insert_chart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text('Нет выбранного графика', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showChartMenu(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Создать график'),
          ),
        ],
      ),
    );
  }
}

/// {@template chart_settings_content}
/// Контент для отображения настроек выбранного графика
/// Получает выбранный график и отображает соответствующие ему настройки через плагин ChartRegistry
/// {@endtemplate}
class _ChartSettingsContent extends ConsumerWidget {
  /// Выбранный график для отображения настроек
  final FloatingChartData selectedChart;
  /// Коллбек для обновления состояния графика (после изменения настроек)
  final void Function(int, ChartState) onUpdateChartState;
  /// Коллбек для создания нового графика указанного типа
  final VoidCallback onTogglePanel;

  const _ChartSettingsContent({
    required this.selectedChart,
    required this.onUpdateChartState,
    required this.onTogglePanel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plugin = ChartRegistry.get(selectedChart.type);
    
    // Используем Selector для обновления только при изменении состояния конкретного графика
    // (состояние графика может меняться, но сам список графиков не обязательно)
    final controls = plugin.buildControls(selectedChart, () {}, ref);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Настройки: ${selectedChart.type.name}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onTogglePanel,
                icon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurfaceVariant),
                tooltip: 'Свернуть панель',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const Divider(),
          ...controls,
        ],
      ),
    );
  }
}


/// {@template collapsed_content}
/// Контент для свернутого состояния панели
/// Показывает иконку и название для доступа к настройкам
/// {@endtemplate}
class _CollapsedContent extends StatelessWidget {
  /// Коллбек для сворачивания панели
  final VoidCallback onToggle;

  const _CollapsedContent({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onToggle,
            icon: const Icon(Icons.chevron_right, size: 28),
            tooltip: 'Развернуть панель',
            padding: const EdgeInsets.all(8),
            style: IconButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          RotatedBox(
            quarterTurns: 1,
            child: Text(
              'Настройки',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500, 
                color: theme.colorScheme.onSurfaceVariant
              ),
            ),
          ),
        ],
      ),
    );
  }
}