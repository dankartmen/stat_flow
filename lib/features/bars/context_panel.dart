import 'package:expandable/expandable.dart';
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = _isExpanded ? 300.0 : 48.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: panelWidth,
      color: Colors.grey[100],
      clipBehavior: Clip.hardEdge,
      onEnd: () {
        if (_isExpanded) {
          setState(() => _showContent = true);
        }
      },
      child: _isExpanded && _showContent
          ? _buildExpandedContent()
          : _buildCollapsedContent(),
    );
  }

  
  Widget _buildCollapsedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _togglePanel,
            icon: Icon(Icons.chevron_right, color: Colors.grey[600], size: 28),
            tooltip: 'Развернуть панель',
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
          const SizedBox(height: 8),
          RotatedBox(
            quarterTurns: 1,
            child: Text(
              'Настройки',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildExpandedContent() {
    final isDatasetLoaded = widget.dataset != null;

    if (!isDatasetLoaded) {
      return _buildNoDatasetContent();
    }

    if (widget.selectedChart == null) {
      return _buildNoChartContent();
    }

    // Есть выбранный график
    final plugin = ChartRegistry.get(widget.selectedChart!.type);
    final controls = plugin.buildControls(widget.selectedChart!, () {}, ref);

    return SizedBox(
      width: 300,
      child: _buildChartSettingsContent(controls));
  }

  Widget _buildNoDatasetContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Датасет не загружен', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDataset, // можно сделать _loadDataset асинхронным
              child: const Text('Загрузить датасет'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChartContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text('Нет выбранного графика', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showChartMenu(context),
            child: const Text('Создать график'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSettingsContent(List<Widget> controls) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Настройки: ${widget.selectedChart!.type.name}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: 6),
              IconButton(
                onPressed: _togglePanel,
                icon: Icon(Icons.chevron_left, color: Colors.grey[600]),
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

  /// Отображает всплывающее меню с доступными типами графиков
  void _showChartMenu(BuildContext context) {
    // Находим позицию кнопки, чтобы привязать меню к ней
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero),
          button.localToGlobal(button.size.bottomRight(Offset.zero)),
        ),
        Offset.zero & MediaQuery.of(context).size,
      ),
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


  Future<void> _loadDataset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TablePreviewScreen()),
    );

    if (result != null && result is Dataset) {
      ref.read(datasetProvider.notifier).state = result;
    }
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
        return Icons.insert_chart; 
    }
  }
}