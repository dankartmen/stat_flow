import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/canvas/canvas_workspace.dart';
import 'package:stat_flow/features/charts/chart_renderer.dart';
import '../../core/providers/providers.dart';
import '../bars/context_panel.dart';
import '../bars/top_nav_bar.dart';
import '../charts/chart_registry.dart';
import '../charts/chart_state.dart';
import '../charts/chart_type.dart';
import '../table/widget/full_table_screen.dart';
import '../charts/floating_chart/floating_chart_container.dart';
import '../charts/floating_chart/floating_chart_data.dart';
import '../charts/fullscreen_chart.dart';
import '../table/widget/table_preview_screen.dart';
import 'welcome_dialog.dart';

/// {@template main_screen}
/// Главный экран приложения Stat Flow
/// 
/// Представляет собой рабочую область с:
/// - Левая боковая панель навигации (загрузка данных, создание графиков)
/// - Центральный канвас для размещения и взаимодействия с графиками
/// - Правая панель с информацией о загруженном датасете (сворачиваемая)
/// - Верхняя контекстная панель управления выбранным графиком
/// 
/// Экран управляет жизненным циклом графиков, их созданием,
/// выбором и открытием в полноэкранном режиме.
/// {@endtemplate}
class MainScreen extends ConsumerStatefulWidget {
  /// {@macro main_screen}
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// Счетчик для генерации уникальных идентификаторов графиков
  int _nextChartId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  /// Отображает приветственный диалог при первом запуске
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeDialog(
        onStart: () {},
        onLoadDataset: _loadDataset,
      ),
    );
  }

  /// Загружает датасет через экран предпросмотра таблицы
  /// 
  /// После успешной загрузки:
  /// - Сохраняет датасет в провайдере
  /// - Разворачивает правую панель для отображения данных
  Future<void> _loadDataset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TablePreviewScreen()),
    );

    if (result != null && result is Dataset) {
      ref.read(datasetProvider.notifier).state = result;
      ref.read(rightPanelExpandedProvider.notifier).state = true;
    }
  }

  /// Создает новый график указанного типа
  /// 
  /// Процесс создания:
  /// 1. Получает плагин для типа графика из реестра
  /// 2. Создает начальное состояние графика
  /// 3. Генерирует уникальный ID и начальную позицию
  /// 4. Добавляет график в список и выбирает его
  void _addChart(ChartType type) {
    final dataset = ref.read(datasetProvider);
    if (dataset == null) return;

    final plugin = ChartRegistry.get(type);

    Size initialSize;

    if (type == ChartType.heatmap) {
      final n = dataset.columns.length;
      const desiredCellSize = 38.0;    
      const extraForLabelsAndLegend = 140.0;
      final contentWidth  = n * desiredCellSize + extraForLabelsAndLegend;
      final contentHeight = n * desiredCellSize + extraForLabelsAndLegend + 60;
      initialSize = Size(
        contentWidth.clamp(420.0, 1200.0),
        contentHeight.clamp(380.0, 1000.0),
      );
    } else {
      initialSize = const Size(520, 380);
    }

    final newChart = FloatingChartData(
      id: _nextChartId++,
      type: type,
      dataset: dataset,
      state: plugin.createState(),
      position: Offset(50 + _nextChartId * 20.0, 50 + _nextChartId * 20.0),
      size: initialSize,
    );

    ref.read(chartsProvider.notifier).addChart(newChart, ref);
    ref.read(selectedChartIdProvider.notifier).state = newChart.id;
  }


  /// Отображает диалог с информацией о приложении
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О приложении'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stat Flow v1.0.0'),
            SizedBox(height: 16),
            Text(
              'Приложение для визуализации и анализа данных.\n\n'
              'Возможности:\n'
              '• Загрузка CSV файлов\n'
              '• Интерактивные графики\n'
              '• Статистический анализ\n'
              '• Экспорт изображений',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datasetExists = ref.watch(datasetProvider) != null;
    final currentScreen = ref.watch(currentScreenProvider);

    return Scaffold(
      body: Column(
        children: [
          // Верхняя панель навигации
          TopNavBar(
            onLoadDataset: _loadDataset,
            onShowInfo: _showInfoDialog,
            currentScreen: currentScreen,
            onScreenChanged: (screen) =>
                ref.read(currentScreenProvider.notifier).state = screen,
          ),
          Expanded(
            child: Row(
              children: [
                // Левая контекстная панель
                _LeftPanel(
                  onAddChart: _addChart,
                  onUpdateChartState: (id, newState) {
                    ref.read(chartsProvider.notifier).updateChartState(id, newState);
                  },
                ),
                // Центральная область
                Expanded(
                  child: IndexedStack(
                    index: currentScreen == ScreenType.canvas ? 0 : 1,
                    children: [
                      // Канвас с графиками
                      const _CanvasArea(),
                      if (datasetExists)
                        const _FullTableArea()
                      else
                        const Center(child: Text('Нет данных')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _LeftPanel extends ConsumerWidget {
  final void Function(ChartType) onAddChart;
  final void Function(int, ChartState) onUpdateChartState;

  const _LeftPanel({
    required this.onAddChart,
    required this.onUpdateChartState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(datasetProvider);
    final selectedChart = ref.watch(
      selectedChartIdProvider.select(
        (id) {
          if (id == null) return null;
          final charts = ref.read(chartsProvider);
          return charts
              .cast<FloatingChartData?>()
              .firstWhere((c) => c?.id == id, orElse: () => null);
        },
      ),
    );

    return RepaintBoundary(
      child: ContextPanel(
        dataset: dataset,
        selectedChart: selectedChart,
        onAddChart: onAddChart,
        onUpdateChartState: onUpdateChartState,
      ),
    );
  }
}

class _CanvasArea extends ConsumerWidget {
  const _CanvasArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartIds = ref.watch(chartIdsProvider);
    final selectedId = ref.watch(selectedChartIdProvider);
    final dataset = ref.watch(datasetProvider);

    /// Обработчики событий для графиков на канвасе
    
    void onSelectChart(int id) {
      ref.read(chartsProvider.notifier).selectChart(id);
      ref.read(selectedChartIdProvider.notifier).state = id;
    }

    void onPositionChanged(int id, Offset pos) {
      ref.read(chartsProvider.notifier).updatePosition(id, pos);
    }

    void onSizeChanged(int id, Size size) {
      ref.read(chartsProvider.notifier).updateSize(id, size);
    }

    void onCloseChart(int id) {
      ref.read(chartsProvider.notifier).removeChart(id);
      if (selectedId == id) {
        final newSelectedChart = chartIds.isNotEmpty
          ? chartIds.last
          : null;
        ref.read(selectedChartIdProvider.notifier).state = newSelectedChart;
      }
    }

    void onFullscreen(int id){
      final charts = ref.read(chartsProvider);
      final chart = charts.firstWhere((c) => c.id == id);
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullscreenChart(
            title: chart.type.name,
            child: ChartRenderer.build(chart),
          )
        ),
      );
    }

    if (chartIds.isEmpty && dataset != null){
      return const _EmptyCanvasState();
    }

    final charts = ref.watch(chartsProvider);
    final children = charts.map((chart) {
      return FloatingChart(
        key: ValueKey(chart.id),
        data: chart,
        isSelected: chart.id == selectedId,
        onPositionChanged: (pos) => onPositionChanged(chart.id, pos),
        onSizeChanged: (size) => onSizeChanged(chart.id, size),
        onSelect: () => onSelectChart(chart.id),
        onClose: () => onCloseChart(chart.id),
        onFullscreen: () => onFullscreen(chart.id),
        child: ChartRenderer.build(chart),
      );
    }).toList();

    return CanvasWorkspace(
      children: children
    );
  }
}

class _EmptyCanvasState extends StatelessWidget{
  const _EmptyCanvasState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_chart, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Добавьте график через боковое меню',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      )
    );
  }
}


class _FullTableArea extends ConsumerWidget {
  const _FullTableArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(datasetProvider);
    return FullTableScreen(dataset: dataset!);
  }
}