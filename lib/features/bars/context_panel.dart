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
/// Контекстная панель для настройки графиков и управления датасетом.
///
/// Отображает контекстные элементы управления в зависимости от состояния:
/// - Если датасет не загружен: показывает сообщение и кнопку загрузки.
/// - Если датасет загружен, но график не выбран: показывает кнопку создания графика.
/// - Если выбран график: отображает настройки этого графика через соответствующий плагин.
///
/// Используется для предоставления быстрого доступа к настройкам текущего графика.
/// Поддерживает сворачивание/разворачивание с анимацией.
/// {@endtemplate}
class ContextPanel extends ConsumerStatefulWidget {
  /// Текущий загруженный датасет (может быть null).
  final Dataset? dataset;

  /// Выбранный в данный момент график (может быть null).
  final FloatingChartData? selectedChart;

  /// Колбэк для создания нового графика указанного типа.
  final void Function(ChartType) onAddChart;

  /// Колбэк для обновления состояния графика (после изменения настроек).
  final void Function(int, ChartState) onUpdateChartState;

  /// {@macro context_panel}
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

/// Состояние контекстной панели.
/// Управляет анимацией сворачивания/разворачивания.
class _ContextPanelState extends ConsumerState<ContextPanel> {
  bool _isExpanded = true;
  bool _showContent = true;
  
  /// Переключает состояние панели (свёрнута/развёрнута).
  /// 
  /// При сворачивании контент скрывается сразу, при разворачивании
  /// появляется с задержкой, чтобы создать плавный эффект.
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
/// Контент для развёрнутого состояния панели.
/// 
/// Содержит:
/// - Заголовок с кнопкой сворачивания
/// - Секцию создания графика (если датасет загружен)
/// - Контент в зависимости от наличия графика (настройки или подсказки)
/// {@endtemplate}
class _ExpandedContent extends ConsumerWidget {
  final Dataset? dataset;
  final FloatingChartData? selectedChart;
  final void Function(ChartType) onAddChart;
  final void Function(int, ChartState) onUpdateChartState;
  final VoidCallback onTogglePanel;

  const _ExpandedContent({
    required this.dataset,
    required this.selectedChart,
    required this.onAddChart,
    required this.onUpdateChartState,
    required this.onTogglePanel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Верхняя панель с заголовком и кнопкой сворачивания
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Управление',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onTogglePanel,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Свернуть панель',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Секция создания графика (активна только если датасет загружен)
        if (dataset != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AddChartSection(onAddChart: onAddChart),
          ),
        // Контент в зависимости от наличия выбранного графика
        Expanded(
          child: dataset == null
              ? const _NoDatasetContent()
              : selectedChart == null
                  ? const _NoChartSelectedHint()
                  : _ChartSettingsContent(
                      selectedChart: selectedChart!,
                      onUpdateChartState: onUpdateChartState,
                    ),
        ),
      ],
    );
  }
}

/// {@template no_dataset_content}
/// Отображается, когда датасет не загружен.
/// Показывает сообщение и кнопку для загрузки датасета.
/// {@endtemplate}
class _NoDatasetContent extends StatelessWidget {
  const _NoDatasetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Датасет не загружен',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите кнопку "Загрузить датасет"\nв верхней панели',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// {@template chart_settings_content}
/// Контент для отображения настроек выбранного графика.
/// 
/// Получает выбранный график и через плагин из [ChartRegistry] строит элементы управления.
/// Использует [Selector] для оптимизации перестроек.
/// {@endtemplate}
class _ChartSettingsContent extends ConsumerWidget {
  final FloatingChartData selectedChart;
  final void Function(int, ChartState) onUpdateChartState;

  const _ChartSettingsContent({
    required this.selectedChart,
    required this.onUpdateChartState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plugin = ChartRegistry.get(selectedChart.type);
    
    // Для перестроения используем Selector, который отслеживает изменения только состояния
    final controls = plugin.buildControls(selectedChart, () {}, ref);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Настройки: ${selectedChart.type.name}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const Divider(),
          ...controls,
        ],
      ),
    );
  }
}

/// {@template collapsed_content}
/// Контент для свёрнутого состояния панели.
/// Показывает иконку и вертикальную надпись "Настройки".
/// {@endtemplate}
class _CollapsedContent extends StatelessWidget {
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

/// {@template add_chart_section}
/// Секция для добавления нового графика.
/// Всегда отображается в верхней части панели (при загруженном датасете).
/// 
/// При нажатии показывает меню со всеми доступными типами графиков.
/// {@endtemplate}
class _AddChartSection extends StatelessWidget {
  final void Function(ChartType) onAddChart;

  const _AddChartSection({required this.onAddChart});

  /// Показывает меню выбора типа графика.
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
              Expanded(child: Text(type.name, style: const TextStyle(overflow: TextOverflow.ellipsis))),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Возвращает иконку для соответствующего типа графика.
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
      case ChartType.pairplotchart:
        return Icons.grid_view;
      case ChartType.kaplanmeier:
        return Icons.line_axis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showChartMenu(context),
          icon: const Icon(Icons.add_chart),
          label: const Text('Создать график'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}

/// {@template no_chart_selected_hint}
/// Отображается, когда датасет загружен, но ни один график не выбран.
/// 
/// Показывает иконку и подсказку, что нужно нажать на график на канвасе.
/// {@endtemplate}
class _NoChartSelectedHint extends StatelessWidget {
  const _NoChartSelectedHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Ни один график не выбран',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите на график на канвасе,\nчтобы настроить его',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}