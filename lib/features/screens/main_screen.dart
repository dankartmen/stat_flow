import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/canvas/canvas_workspace.dart';
import 'package:stat_flow/features/charts/chart_renderer.dart';
import 'package:stat_flow/features/charts/chart_state.dart';
import '../charts/chart_registry.dart';
import '../charts/chart_type.dart';
import '../charts/heatmap/model/heatmap_state.dart';
import '../table/widget/full_table_screen.dart';
import '../charts/floating_chart/floating_chart_container.dart';
import '../charts/floating_chart/floating_chart_data.dart';
import '../charts/fullscreen_chart.dart';
import '../bars/left_sidebar.dart';
import '../bars/right_dataset_panel.dart';
import '../table/widget/table_preview_screen.dart';
import '../bars/top_control_panel.dart';
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

  /// Флаг расширения правой панели
  bool _isRightPanelExpanded = true;

  /// Ширина правой панели в расширенном состоянии
  static const double _rightPanelExpandedWidth = 280;

  /// Ширина правой панели в свернутом состоянии (только иконка)
  static const double _rightPanelCollapsedWidth = 0;

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

  /// Открывает экран с полной таблицей данных
  /// 
  /// Проверяет наличие загруженного датасета и открывает [FullTableScreen] с ним.
  void _showFullTable() {
    if (_dataset == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullTableScreen(
          dataset: _dataset!,
        ),
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
        _isRightPanelExpanded = true; // Автоматически расширяем правую панель при загрузке датасета
      });
    }
  }

  /// Переключает состояние правой панели (развернуто/свернуто)
  void _toggleRightPanel() {
    setState(() {
      _isRightPanelExpanded = !_isRightPanelExpanded;
    });
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
    if (_dataset == null) return;

    final plugin = ChartRegistry.get(type.name);

    final newChart = FloatingChartData(
      id: _nextChartId++,
      type: type,
      dataset: _dataset!,
      state: plugin.createState(),
      position: Offset(50 + _charts.length * 20.0, 50 + _charts.length * 20.0),
      size: const Size(300, 200),
    );

    setState(() {
      _charts.add(newChart);
      _selectedChartId = newChart.id;
    });
  }

  /// Выбирает график по ID
  void _selectChart(int id) {
    setState(() {
      final index = _charts.indexWhere((c) => c.id == id);
      if (index == -1) return;

      final chart = _charts.removeAt(index);
      _charts.add(chart);

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
          child: ChartRenderer.build(chart),
        ),
      ),
    );
  }

  
  /// Возвращает данные выбранного графика или null
  FloatingChartData? _getSelectedChart() {
    if (_selectedChartId == null) return null;
    return _charts.firstWhere((chart) => chart.id == _selectedChartId);
  }

  double get _rightPanelWidth {
    return _isRightPanelExpanded 
        ? _rightPanelExpandedWidth 
        : _rightPanelCollapsedWidth;
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
              right: _rightPanelWidth, // Ширина правой панели с датасетом
              top: 0,
              child: TopControlPanel(
                chart: selectedChart,
                onChanged: () {
                  setState(() {}); // Обновляем состояние для перерисовки панели управления
                },
              ),
            ),

          // Основная область с графиками
          Positioned.fill(
            left: 72,
            right: _rightPanelWidth,
            top: selectedChart != null ? 80 : 0, // Высота панели управления
            child: Container(
              color: Colors.grey[100],
              child: CanvasWorkspace(
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
                        child: ChartRenderer.build(chart),
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
              onShowTable: _showFullTable,
              isDatasetLoaded: _dataset != null,
            ),
          ),

          // Правая панель с информацией о датасете
          if (_dataset != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleRightPanel,
                    child: Container(
                      width: 16,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                          topRight: Radius.circular(_isRightPanelExpanded ? 0 : 4),
                          bottomRight: Radius.circular(_isRightPanelExpanded ? 0 : 4),
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
                          _isRightPanelExpanded ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.grey[400],
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _rightPanelWidth,
                    child: RightDatasetPanel(
                      dataset: _dataset!,
                      isExpanded: _isRightPanelExpanded,
                    ),
                  ),
                ],
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