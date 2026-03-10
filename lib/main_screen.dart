import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'features/charts/chart_type.dart';
import 'features/charts/heatmap/color/heatmap_color_mapper.dart';
import 'features/charts/heatmap/color/heatmap_palette.dart';
import 'features/charts/heatmap/widgets/heatmap_view.dart';
import 'floating_chart_container.dart';
import 'floating_chart_data.dart';
import 'fullscreen_chart.dart';
import 'left_sidebar.dart';
import 'right_dataset_panel.dart';
import 'table_preview_screen.dart';
import 'top_control_panel.dart';
import 'welcome_dialog.dart';

/// {@template main_screen}
/// Главный экран приложения с системой плавающих окон для графиков
/// 
/// Реализует интерфейс рабочего стола (dashboard) с:
/// - Левой боковой панелью навигации
/// - Правой панелью с информацией о датасете
/// - Верхней контекстной панелью управления (для выбранного графика)
/// - Центральной областью с плавающими окнами графиков
/// 
/// Поддерживает:
/// - Загрузку CSV-файлов через экран предпросмотра
/// - Создание графиков различных типов (тепловая карта, диаграмма рассеяния и др.)
/// - Перемещение и изменение размеров окон
/// - Выделение активного окна
/// - Полноэкранный режим
/// - Управление параметрами отображения через верхнюю панель
/// {@endtemplate}
class MainScreen extends StatefulWidget {
  /// {@macro main_screen}
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Загруженный датасет
  Dataset? _dataset;

  /// Флаг отображения приветственного оверлея
  bool _showWelcomeOverlay = true;

  /// Счетчик для генерации уникальных ID графиков
  int _nextChartId = 0;

  /// Список плавающих графиков
  final List<FloatingChartData> _charts = [];

  /// ID текущего выбранного графика
  int? _selectedChartId;

  // Состояния для панели управления тепловой карты
  /// Выбранная цветовая палитра
  HeatmapPalette _selectedPalette = HeatmapPalette.redBlue;

  /// Количество сегментов для дискретного режима
  int _segments = 10;

  /// Режим отображения только верхнего треугольника
  bool _triangleMode = false;

  /// Включение кластеризации
  bool _clusterEnabled = false;

  /// Режим раскраски (непрерывный/дискретный)
  HeatmapColorMode _colorMode = HeatmapColorMode.discrete;

  @override
  void initState() {
    super.initState();
    // Показываем приветственный диалог после первой отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  /// Отображает приветственный диалог
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeDialog(
        onStart: () {
          setState(() => _showWelcomeOverlay = false);
        },
        onLoadDataset: () => _loadDataset(),
      ),
    );
  }

  /// Загружает датасет через экран предварительного просмотра
  /// 
  /// Открывает [TablePreviewScreen] для выбора и предпросмотра CSV-файла.
  /// При успешной загрузке сохраняет датасет и скрывает приветственный оверлей.
  Future<void> _loadDataset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TablePreviewScreen(),
      ),
    );

    if (result != null && result is Dataset) {
      setState(() {
        _dataset = result;
        _showWelcomeOverlay = false;
      });
    }
  }

  /// Добавляет новый график указанного типа
  /// 
  /// Принимает:
  /// - [type] — тип создаваемого графика
  /// 
  /// Особенности:
  /// - Генерирует уникальный ID для графика
  /// - Устанавливает начальную позицию со смещением (каскадное расположение)
  /// - Автоматически выбирает созданный график
  void _addChart(ChartType type) {
    setState(() {
      final newChart = FloatingChartData(
        id: _nextChartId++,
        type: type,
        dataset: _dataset!,
        position: Offset(100 + _charts.length * 30, 100 + _charts.length * 30),
      );
      _charts.add(newChart);
      _selectedChartId = newChart.id;
    });
  }

  /// Выбирает график по ID
  void _selectChart(int id) {
    setState(() {
      _selectedChartId = id;
    });
  }

  /// Удаляет график по ID
  /// 
  /// При удалении выбранного графика автоматически выбирается последний
  /// оставшийся график или сбрасывается выделение.
  void _removeChart(int id) {
    setState(() {
      _charts.removeWhere((chart) => chart.id == id);
      if (_selectedChartId == id) {
        _selectedChartId = _charts.isNotEmpty ? _charts.last.id : null;
      }
    });
  }

  /// Обновляет позицию графика
  void _updateChartPosition(int id, Offset newPosition) {
    final index = _charts.indexWhere((chart) => chart.id == id);
    if (index != -1) {
      setState(() {
        _charts[index] = _charts[index].copyWith(position: newPosition);
      });
    }
  }

  /// Обновляет размер графика
  void _updateChartSize(int id, Size newSize) {
    final index = _charts.indexWhere((chart) => chart.id == id);
    if (index != -1) {
      setState(() {
        _charts[index] = _charts[index].copyWith(size: newSize);
      });
    }
  }

  /// Открывает график в полноэкранном режиме
  /// 
  /// Принимает:
  /// - [id] — ID графика для открытия
  /// 
  /// Открывает [FullscreenChart] с соответствующим содержимым.
  void _openFullscreen(int id) {
    final chart = _charts.firstWhere((c) => c.id == id);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullscreenChart(
          title: chart.type.name,
          child: _buildChartContent(chart),
        ),
      ),
    );
  }

  /// Строит содержимое графика в зависимости от его типа
  /// 
  /// Принимает:
  /// - [chart] — данные графика
  /// 
  /// Возвращает:
  /// - [Widget] — соответствующий виджет графика
  /// 
  /// Особенности:
  /// - Для тепловой карты использует [HeatmapView] с текущими настройками
  /// - Для остальных типов отображает заглушку "в разработке"
  Widget _buildChartContent(FloatingChartData chart) {
    switch (chart.type) {
      case ChartType.heatmap:
        return HeatmapView(
          matrix: chart.dataset.corr(),
          palette: _selectedPalette,
          segments: _segments,
          triangleMode: _triangleMode,
          clusterEnabled: _clusterEnabled,
          colorMode: _colorMode,
        );
      default:
        return const Center(child: Text('График в разработке'));
    }
  }

  /// Возвращает данные выбранного графика или null
  FloatingChartData? _getSelectedChart() {
    if (_selectedChartId == null) return null;
    return _charts.firstWhere((chart) => chart.id == _selectedChartId);
  }

  @override
  Widget build(BuildContext context) {
    final selectedChart = _getSelectedChart();

    return Scaffold(
      body: Stack(
        children: [
          // Верхняя панель управления (отображается только при выбранном графике)
          if (selectedChart != null)
            Positioned(
              left: 72, // Ширина левой боковой панели
              right: 280, // Ширина правой панели с датасетом
              top: 0,
              child: TopControlPanel(
                chartType: selectedChart.type,
                // Параметры для тепловой карты
                palette: _selectedPalette,
                segments: _segments,
                triangleMode: _triangleMode,
                clusterEnabled: _clusterEnabled,
                colorMode: _colorMode,
                onPaletteChanged: (p) => setState(() => _selectedPalette = p),
                onSegmentsChanged: (s) => setState(() => _segments = s),
                onTriangleModeChanged: (v) => setState(() => _triangleMode = v),
                onClusterEnabledChanged: (v) => setState(() => _clusterEnabled = v),
                onColorModeChanged: (m) => setState(() => _colorMode = m),
              ),
            ),

          // Основная область с графиками
          Positioned.fill(
            left: 72,
            right: 280,
            top: selectedChart != null ? 80 : 0, // Высота панели управления
            child: Container(
              color: Colors.grey[100],
              child: Stack(
                children: [
                  // Плавающие графики
                  ..._charts.map((chart) => FloatingChart(
                        key: ValueKey(chart.id),
                        data: chart,
                        isSelected: _selectedChartId == chart.id,
                        onSelect: () => _selectChart(chart.id),
                        onPositionChanged: (pos) => _updateChartPosition(chart.id, pos),
                        onSizeChanged: (size) => _updateChartSize(chart.id, size),
                        onClose: () => _removeChart(chart.id),
                        onFullscreen: () => _openFullscreen(chart.id),
                        child: _buildChartContent(chart),
                      )),

                  // Подсказка, если нет графиков
                  if (_charts.isEmpty && _dataset != null)
                    _buildEmptyState(),
                ],
              ),
            ),
          ),

          // Левая боковая панель с иконками
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: LeftSidebar(
              onLoadDataset: _loadDataset,
              onAddChart: _addChart,
              onShowInfo: _showInfoDialog,
              isDatasetLoaded: _dataset != null,
            ),
          ),

          // Правая панель с информацией о датасете
          if (_dataset != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: RightDatasetPanel(
                dataset: _dataset!,
              ),
            ),

          // Приветственный оверлей
          if (_showWelcomeOverlay)
            _buildWelcomeOverlay(),
        ],
      ),
    );
  }

  /// Строит состояние пустой области (когда датасет загружен, но графиков нет)
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

  /// Строит приветственный оверлей (альтернатива диалогу)
  Widget _buildWelcomeOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.analytics,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Stat Flow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Визуализация и анализ данных',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _showWelcomeOverlay = false);
                    _loadDataset();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                  child: const Text('Загрузить датасет'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _showWelcomeOverlay = false);
                  },
                  child: const Text('Пропустить'),
                ),
              ],
            ),
          ),
        ),
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
              '• Экспорт изображений'
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
}