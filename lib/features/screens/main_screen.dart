import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/canvas/canvas_workspace.dart';
import 'package:stat_flow/features/charts/chart_renderer.dart';
import '../../core/providers/providers.dart';
import '../bars/context_panel.dart';
import '../bars/top_nav_bar.dart';
import '../charts/chart_registry.dart';
import '../charts/chart_state.dart';
import '../charts/chart_type.dart';
import '../charts/pairplot/pairplot_state.dart';
import '../charts/pairplot/pairplot_view.dart';
import '../charts/scatterplot/scatter_state.dart';
import '../lab2/image_lab_screen.dart';
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
  /// Увеличивается при каждом создании нового графика.
  int _nextChartId = 0;

  @override
  void initState() {
    super.initState();
    // Показываем приветственный диалог после первой отрисовки.
    // Используем addPostFrameCallback, чтобы избежать вызова build до завершения инициализации.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  /// Проверяет, запускалось ли приложение ранее, и при необходимости показывает диалог выбора лабораторной.
  /// - Если в SharedPreferences нет ключа 'active_lab' – первый запуск: показываем [WelcomeDialog].
  /// - Иначе загружаем сохранённую лабораторную и устанавливаем в провайдер.
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final activeLabName = prefs.getString('active_lab');
    if (activeLabName == null) {
      // Первый запуск: показываем диалог выбора
      final lab = await WelcomeDialog.show(context);
      if (lab != null) {
        ref.read(activeLabProvider.notifier).state = lab;
      }
    } else {
      // Загружаем сохранённую лабораторную
      final lab = LabType.values.firstWhere((e) => e.name == activeLabName);
      ref.read(activeLabProvider.notifier).state = lab;
    }
  }

  /// Загружает датасет через экран предпросмотра таблицы.
  /// 
  /// Принимает:
  /// - Результат навигации: объект [Dataset] при успешной загрузке.
  /// 
  /// После успешной загрузки сохраняет датасет в [tabularDatasetProvider].
  Future<void> _loadDataset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TablePreviewScreen()),
    );

    if (result != null && result is Dataset) {
      ref.read(tabularDatasetProvider.notifier).state = result;
    }
  }

  /// Создаёт новый график указанного типа.
  /// 
  /// Процесс создания:
  /// 1. Получает плагин для типа графика из реестра
  /// 2. Создаёт начальное состояние графика
  /// 3. Генерирует уникальный ID и начальную позицию
  /// 4. Добавляет график в список и выбирает его
  /// 
  /// Особое поведение для разных типов графиков:
  /// - Тепловая карта (heatmap): размер вычисляется динамически на основе количества колонок
  /// - Pair Plot (pairplotchart): фиксированный размер 700x600
  /// - Остальные: стандартный размер 520x380
  void _addChart(ChartType type) {
    final dataset = ref.read(tabularDatasetProvider);
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
    } else if (type == ChartType.pairplotchart) {
      // Pair Plot требует больше места для матрицы
      initialSize = const Size(700, 600);
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
      onCellTap: type == ChartType.pairplotchart ? _onPairPlotCellTap : null,
      onUpdateState: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(_nextChartId++, newState);
      },
    );

    ref.read(chartsProvider.notifier).addChart(newChart, ref);
    ref.read(selectedChartIdProvider.notifier).state = newChart.id;
  }

  /// Обработчик тапа на ячейку Pair Plot.
  /// 
  /// Принимает:
  /// - [xCol] – имя колонки для оси X.
  /// - [yCol] – имя колонки для оси Y.
  /// 
  /// Создаёт новый scatter plot для выбранной пары колонок
  /// и добавляет его на канвас.
  void _onPairPlotCellTap(String xCol, String yCol) {
    final dataset = ref.read(tabularDatasetProvider);
    if (dataset == null) return;

    final newScatter = FloatingChartData(
      id: _nextChartId++,
      type: ChartType.scatter,
      dataset: dataset,
      state: ScatterState(firstColumnName: xCol, secondColumnName: yCol),
      position: Offset(100 + _nextChartId * 20.0, 100 + _nextChartId * 20.0),
      size: const Size(500, 400),
      onUpdateState: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(_nextChartId++, newState);
      },
    );

    ref.read(chartsProvider.notifier).addChart(newScatter, ref);
    ref.read(selectedChartIdProvider.notifier).state = newScatter.id;
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
    final activeLab = ref.watch(activeLabProvider);

    // Если лабораторная ещё не выбрана, показываем заглушку (хотя WelcomeDialog должен был выбрать)
    if (activeLab == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Для изображений – отдельный экран
    if (activeLab == LabType.image) {
      return const ImageLabScreen();
    }

    // Для табличных данных – старый интерфейс (с небольшими правками)
    return _buildTabularInterface();
  }

  /// Строит интерфейс для работы с табличными данными (CSV).
  /// 
  /// Возвращает [Scaffold] с верхней панелью, левой панелью управления
  /// и областью канваса/таблицы.
  Widget _buildTabularInterface() {
    final datasetExists = ref.watch(tabularDatasetProvider) != null;
    final currentScreen = ref.watch(currentScreenProvider);

    return Scaffold(
      body: Column(
        children: [
          const TopNavBar(),
          Expanded(
            child: Row(
              children: [
                _LeftPanel(
                  onAddChart: _addChart,
                  onUpdateChartState: (id, newState) {
                    ref.read(chartsProvider.notifier).updateChartState(id, newState);
                  },
                ),
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

  /// {@macro left_panel}
  const _LeftPanel({
    required this.onAddChart,
    required this.onUpdateChartState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(tabularDatasetProvider);
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
/// Теперь реагирует только на список идентификаторов, а не на полные данные графиков.
/// {@endtemplate}
class _CanvasArea extends ConsumerWidget {
  /// {@macro canvas_area}
  const _CanvasArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Читаем ТОЛЬКО список идентификаторов, который меняется только при add/remove
    final chartIds = ref.watch(chartIdListProvider);
    final dataset = ref.watch(tabularDatasetProvider);

    // Если графиков нет, но датасет загружен — показываем приглашение
    if (chartIds.isEmpty && dataset != null) {
      return const _EmptyCanvasState();
    }

    // Строим легковесные обёртки для каждого id
    final children = chartIds.map((id) => _ChartItem(id: id)).toList();

    return CanvasWorkspace(children: children);
  }
}

/// {@template chart_item}
/// Отдельный наблюдатель за одним графиком на канвасе.
/// Получает данные конкретного графика через select и реагирует только на его изменения.
/// Содержит логику выбора, перемещения, изменения размера, закрытия и полноэкранного режима.
/// {@endtemplate}
class _ChartItem extends ConsumerWidget {
  /// Идентификатор графика, за которым наблюдает этот виджет.
  final int id;

  /// {@macro chart_item}
  const _ChartItem({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Подписываемся только на свой объект FloatingChartData
    final chart = ref.watch(chartsProvider.select((list) {
      try {
        return list.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }));

    // Если график исчез (например, удалён), ничего не рисуем
    if (chart == null) {
      return const SizedBox.shrink();
    }

    // Состояние выделения
    final selectedId = ref.watch(selectedChartIdProvider);
    final isSelected = selectedId == id;

    /// Обработчик выбора графика.
    void onSelect() {
      ref.read(chartsProvider.notifier).selectChart(id);
      ref.read(selectedChartIdProvider.notifier).state = id;
    }

    /// Обработчик изменения позиции графика.
    void onPositionChanged(Offset pos) {
      ref.read(chartsProvider.notifier).updatePosition(id, pos);
    }

    /// Обработчик изменения размера графика.
    void onSizeChanged(Size size) {
      ref.read(chartsProvider.notifier).updateSize(id, size);
    }

    /// Обработчик закрытия графика.
    /// При закрытии выбранного графика автоматически выбирается последний из оставшихся (если есть).
    void onClose() {
      // Удаляем из основного хранилища и из списка идентификаторов
      ref.read(chartsProvider.notifier).removeChart(id, ref);
      
      // Если закрыт выделенный график, переключаем выделение
      if (selectedId == id) {
        final remainingIds = ref.read(chartIdListProvider);
        ref.read(selectedChartIdProvider.notifier).state =
            remainingIds.isNotEmpty ? remainingIds.last : null;
      }
    }

    /// Обработчик открытия графика в полноэкранном режиме.
    void onFullscreen() {
      final fullscreenChart = chart;
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullscreenChart(
            title: fullscreenChart.type.name,
            child: ChartRenderer.build(fullscreenChart),
          ),
        ),
      );
    }

    /// Строит виджет для графика с учётом его типа.
    /// Pair Plot использует специальный виджет с поддержкой onCellTap.
    Widget buildChartWidget(FloatingChartData chart) {
      if (chart.type == ChartType.pairplotchart) {
        return PairPlotView(
          dataset: chart.dataset,
          state: chart.state as PairPlotState,
          onCellTap: chart.onCellTap,
        );
      }
      return ChartRenderer.build(chart);
    }

    return FloatingChart(
      key: ValueKey(id),
      data: chart,
      isSelected: isSelected,
      onPositionChanged: onPositionChanged,
      onSizeChanged: onSizeChanged,
      onSelect: onSelect,
      onClose: onClose,
      onFullscreen: onFullscreen,
      child: buildChartWidget(chart),
    );
  }
}

/// {@template empty_canvas_state}
/// Состояние канваса при отсутствии графиков.
/// Отображает приглашение добавить первый график.
/// {@endtemplate}
class _EmptyCanvasState extends StatelessWidget {
  /// {@macro empty_canvas_state}
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
  /// {@macro full_table_area}
  const _FullTableArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(tabularDatasetProvider);
    return FullTableScreen(dataset: dataset!);
  }
}