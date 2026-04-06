import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/canvas/canvas_workspace.dart';
import 'package:stat_flow/features/charts/chart_renderer.dart';
import '../../core/providers/providers.dart';
import '../bars/context_panel.dart';
import '../bars/right_dataset_panel.dart';
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

    ref.read(chartsProvider.notifier).addChart(newChart);
    ref.read(selectedChartIdProvider.notifier).state = newChart.id;
  }

  /// Определяет тип колонки по её имени
  ColumnType? _getColumnType(String columnName) {
    final dataset = ref.read(datasetProvider);
    if (dataset == null) return null;
    final column = dataset.column(columnName);
    if (column is NumericColumn) return ColumnType.numeric;
    if (column is DateTimeColumn) return ColumnType.dateTime;
    if (column is CategoricalColumn) return ColumnType.categorical;
    if (column is TextColumn) return ColumnType.text;
    return null;
  }

  /// Создает график для указанного поля датасета
  /// 
  /// Используется при создании графика через контекстное меню
  /// правой панели. Автоматически настраивает состояние графика
  /// с выбранным полем.
  void _createChartForField(String fieldName, ChartType chartType) {
    final dataset = ref.read(datasetProvider);
    if (dataset == null) return;

    final plugin = ChartRegistry.get(chartType);
    final state = plugin.createState();
    final columnType = _getColumnType(fieldName);
    final newState = state.withField(fieldName, type: columnType);

    final newChart = FloatingChartData(
      id: _nextChartId++,
      type: chartType,
      dataset: dataset,
      state: newState,
      position: Offset(50 + _nextChartId * 20.0, 50 + _nextChartId * 20.0),
      size: const Size(300, 200),
    );

    ref.read(chartsProvider.notifier).addChart(newChart);
    ref.read(selectedChartIdProvider.notifier).state = newChart.id;
  }

  /// Открывает график в полноэкранном режиме
  void _openFullscreen(int id) {
    final chart = ref.read(chartsProvider).firstWhere((c) => c.id == id);
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

  /// Открывает полноэкранную таблицу данных
  void _showFullTable() {
    final dataset = ref.read(datasetProvider);
    if (dataset == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullTableScreen(dataset: dataset),
      ),
    );
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

  /// Строит состояние пустого канваса (нет графиков, но данные загружены)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Добавьте график через боковое меню',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Строит правую панель с возможностью сворачивания
  Widget _buildRightPanel(Dataset dataset, bool isExpanded) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(rightPanelExpandedProvider.notifier).state = !isExpanded;
            },
            child: Container(
              width: 16,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(isExpanded ? 0 : 4),
                  bottomRight: Radius.circular(isExpanded ? 0 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, 0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isExpanded ? Icons.chevron_right : Icons.chevron_left,
                  color: Colors.grey[400],
                  size: 14,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isExpanded ? 280 : 0,
            child: RightDatasetPanel(
              dataset: dataset,
              isExpanded: isExpanded,
              onCreateChart: _createChartForField,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(datasetProvider);
    final charts = ref.watch(chartsProvider);
    final selectedId = ref.watch(selectedChartIdProvider);
    final currentScreen = ref.watch(currentScreenProvider);

    final selectedChart = selectedId != null
        ? charts.firstWhere((c) => c.id == selectedId)
        : null;

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
                ContextPanel(
                  dataset: dataset,
                  selectedChart: selectedChart,
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
                      CanvasWorkspace(
                        children: [
                          ...charts.map((chart) => FloatingChart(
                                key: ValueKey(chart.id),
                                data: chart,
                                isSelected: chart.id == selectedId,
                                onSelect: () {
                                  ref.read(chartsProvider.notifier).selectChart(chart.id);
                                  ref.read(selectedChartIdProvider.notifier).state = chart.id;
                                },
                                onPositionChanged: (pos) =>
                                    ref.read(chartsProvider.notifier).updatePosition(chart.id, pos),
                                onSizeChanged: (size) =>
                                    ref.read(chartsProvider.notifier).updateSize(chart.id, size),
                                onClose: () {
                                  ref.read(chartsProvider.notifier).removeChart(chart.id);
                                  if (chart.id == selectedId) {
                                    final newSelected = charts.length > 1 ? charts.last.id : null;
                                    ref.read(selectedChartIdProvider.notifier).state = newSelected;
                                  }
                                },
                                onFullscreen: () => _openFullscreen(chart.id),
                                child: ChartRenderer.build(chart),
                              )),
                          if (charts.isEmpty && dataset != null) _buildEmptyState(),
                        ],
                      ),
                      // Таблица данных (встраиваем FullTableScreen как виджет)
                      if (dataset != null)
                        FullTableScreen(dataset: dataset)
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