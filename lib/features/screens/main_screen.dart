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
/// Главный экран приложения Stat Flow.
/// 
/// Представляет собой рабочую область с:
/// - Левая боковая панель (контекстное меню для добавления и настройки графиков)
/// - Центральный канвас для размещения и взаимодействия с графиками
/// - Верхняя панель навигации (загрузка данных, переключение между канвасом и таблицей)
/// 
/// Экран управляет жизненным циклом графиков, их созданием,
/// выбором и открытием в полноэкранном режиме.
/// 
/// TODO: Левая панель должна быть только при типе отображаемого графика Canvas
/// {@endtemplate}
class MainScreen extends ConsumerStatefulWidget {
  /// {@macro main_screen}
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

/// {@template main_screen_state}
/// Состояние главного экрана.
/// Управляет созданием графиков, загрузкой датасета и диалогами.
/// {@endtemplate}
class _MainScreenState extends ConsumerState<MainScreen> {
  /// Счетчик для генерации уникальных идентификаторов графиков.
  int _nextChartId = 0;

  @override
  void initState() {
    super.initState();
    // Показываем приветственный диалог после первой отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  /// Отображает приветственный диалог при первом запуске.
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

  /// Загружает датасет через экран предпросмотра таблицы.
  /// 
  /// После успешной загрузки:
  /// - Сохраняет датасет в провайдере
  Future<void> _loadDataset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TablePreviewScreen()),
    );

    if (result != null && result is Dataset) {
      ref.read(datasetProvider.notifier).state = result;
    }
  }

  /// Создает новый график указанного типа.
  /// 
  /// Процесс создания:
  /// 1. Получает плагин для типа графика из реестра
  /// 2. Создает начальное состояние графика
  /// 3. Генерирует уникальный ID и начальную позицию
  /// 4. Добавляет график в список и выбирает его
  /// 
  /// Особое поведение для тепловой карты (heatmap):
  /// - Размер вычисляется динамически на основе количества колонок
  /// - Желаемый размер ячейки ~20px + место для подписей и легенды (~140px)
  void _addChart(ChartType type) {
    final dataset = ref.read(datasetProvider);
    if (dataset == null) return;

    final plugin = ChartRegistry.get(type);

    Size initialSize;

    // Для тепловой карты размер зависит от количества колонок (квадратная матрица)
    if (type == ChartType.heatmap) {
      final n = dataset.columns.length;
      const desiredCellSize = 20.0;          // Желаемый размер ячейки в пикселях
      const extraForLabelsAndLegend = 140.0; // Запас под подписи осей и легенду
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

  /// Отображает диалог с информацией о приложении.
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
                // Левая контекстная панель (настройки выбранного графика)
                _LeftPanel(
                  onAddChart: _addChart,
                  onUpdateChartState: (id, newState) {
                    ref.read(chartsProvider.notifier).updateChartState(id, newState);
                  },
                ),
                // Центральная область с канвасом или полноэкранной таблицей
                Expanded(
                  child: IndexedStack(
                    index: currentScreen == ScreenType.canvas ? 0 : 1,
                    children: [
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

/// {@template left_panel}
/// Левая панель с контекстными элементами управления.
/// Отображает панель [ContextPanel] для выбранного графика.
/// Использует [RepaintBoundary] для оптимизации перерисовок.
/// {@endtemplate}
class _LeftPanel extends ConsumerWidget {
  /// Колбэк для добавления нового графика.
  final void Function(ChartType) onAddChart;

  /// Колбэк для обновления состояния выбранного графика.
  final void Function(int, ChartState) onUpdateChartState;

  const _LeftPanel({
    required this.onAddChart,
    required this.onUpdateChartState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(datasetProvider);
    final selectedId = ref.watch(selectedChartIdProvider);

    // Выбираем только стабильные данные: id, type, dataset (позиция/размер не важны для панели)
    final chartInfo = ref.watch(chartsProvider.select((charts) {
      if (selectedId == null) return null;
      final chart = charts.cast<FloatingChartData?>().firstWhere(
        (c) => c?.id == selectedId,
        orElse: () => null,
      );
      if (chart == null) return null;
      return (id: chart.id, type: chart.type, dataset: chart.dataset);
    }));

    // Состояние графика – обновляется только при вызове updateChartState
    final chartState = ref.watch(chartsProvider.select((charts) {
      if (selectedId == null) return null;
      final chart = charts.cast<FloatingChartData?>().firstWhere(
        (c) => c?.id == selectedId,
        orElse: () => null,
      );
      return chart?.state;
    }));

    // Собираем временный объект для панели (положение/размер игнорируются)
    FloatingChartData? selectedChart;
    if (chartInfo != null && chartState != null) {
      selectedChart = FloatingChartData(
        id: chartInfo.id,
        type: chartInfo.type,
        dataset: chartInfo.dataset,
        state: chartState,
        position: Offset.zero,
        size: Size.zero,
      );
    }

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

/// {@template canvas_area}
/// Область канваса, содержащая все плавающие графики.
/// Управляет выбором, перемещением, изменением размера, закрытием и полноэкранным режимом.
/// {@endtemplate}
class _CanvasArea extends ConsumerWidget {
  const _CanvasArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartIds = ref.watch(chartIdsProvider);
    final selectedId = ref.watch(selectedChartIdProvider);
    final dataset = ref.watch(datasetProvider);

    /// Обработчик выбора графика.
    void onSelectChart(int id) {
      ref.read(chartsProvider.notifier).selectChart(id);
      ref.read(selectedChartIdProvider.notifier).state = id;
    }

    /// Обработчик изменения позиции графика.
    void onPositionChanged(int id, Offset pos) {
      ref.read(chartsProvider.notifier).updatePosition(id, pos);
    }

    /// Обработчик изменения размера графика.
    void onSizeChanged(int id, Size size) {
      ref.read(chartsProvider.notifier).updateSize(id, size);
    }

    /// Обработчик закрытия графика.
    /// При закрытии выбранного графика автоматически выбирается последний из оставшихся (если есть).
    void onCloseChart(int id) {
      ref.read(chartsProvider.notifier).removeChart(id);
      if (selectedId == id) {
        final newSelectedChart = chartIds.isNotEmpty ? chartIds.last : null;
        ref.read(selectedChartIdProvider.notifier).state = newSelectedChart;
      }
    }

    /// Обработчик открытия графика в полноэкранном режиме.
    void onFullscreen(int id) {
      final charts = ref.read(chartsProvider);
      final chart = charts.firstWhere((c) => c.id == id);
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullscreenChart(
            title: chart.type.name,
            child: ChartRenderer.build(chart),
          ),
        ),
      );
    }

    // Если нет графиков, но датасет загружен — показываем подсказку
    if (chartIds.isEmpty && dataset != null) {
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

    return CanvasWorkspace(children: children);
  }
}

/// {@template empty_canvas_state}
/// Состояние канваса при отсутствии графиков.
/// Отображает приглашение добавить первый график.
/// {@endtemplate}
class _EmptyCanvasState extends StatelessWidget {
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
      ),
    );
  }
}

/// {@template full_table_area}
/// Область отображения полной таблицы данных в режиме просмотра.
/// Используется при переключении на вкладку "Таблица" в верхней панели.
/// {@endtemplate}
class _FullTableArea extends ConsumerWidget {
  const _FullTableArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(datasetProvider);
    return FullTableScreen(dataset: dataset!);
  }
}