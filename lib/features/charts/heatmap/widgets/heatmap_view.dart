import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_legend.dart';

import '../model/correlation_clusterer.dart';
import '../model/correlation_matrix.dart';
import '../color/heatmap_color_mapper.dart';
import '../painter/heatmap_painter.dart';
import '../color/heatmap_palette.dart';

/// {@template heatmap_view}
/// Основной виджет для отображения интерактивной тепловой карты
/// с поддержкой настройки цветов, кластеризации и анимации.
///
/// Особенности:
/// - Интерактивное масштабирование через InteractiveViewer
/// - Подсветка ячейки при наведении мыши
/// - Плавная анимация при смене цветовых схем
/// - Кластеризация матрицы для выявления паттернов
/// - Автоматическое обновление при изменении параметров
/// - Компактная легенда под картой
/// {@endtemplate}
class HeatmapView extends StatefulWidget {
  /// Матрица корреляции для отображения
  final CorrelationMatrix matrix;

  /// Выбранная цветовая палитра 
  final HeatmapPalette palette;

  /// Количество сегментов для дискретного режима отображения
  final int segments;

  /// Режим отображения только верхнего треугольника матрицы
  final bool triangleMode;

  /// Включена ли кластеризация строк и столбцов
  /// для группировки похожих переменных
  final bool clusterEnabled;

  /// Режим отображения цветов: дискретный (segments) или градиентный
  final HeatmapColorMode colorMode;

  /// Отображать ли подписи осей
  final bool showAxisLabels;

  /// {@macro heatmap_view}
  const HeatmapView({
    super.key,
    this.showAxisLabels = false,
    required this.matrix,
    required this.palette,
    required this.segments,
    required this.triangleMode,
    required this.clusterEnabled,
    required this.colorMode,
  });

  @override
  State<HeatmapView> createState() => _HeatmapViewState();
}

class _HeatmapViewState extends State<HeatmapView>
    with SingleTickerProviderStateMixin {
  /// Индекс строки под курсором мыши (для подсветки)
  int? hoverRow;

  /// Индекс колонки под курсором мыши (для подсветки)
  int? hoverCol;

  /// Текущий маппер цветов на основе настроек (палитра, сегменты, режим)
  late HeatmapColorMapper _currentMapper;

  /// Контроллер анимации для плавных переходов между цветовыми схемами
  late AnimationController _controller;

  /// Предыдущий маппер для интерполяции во время анимации
  late HeatmapColorMapper _previousMapper;

  /// Контроллер трансформации для масштабирования
  final TransformationController _zoomController = TransformationController();

  /// Кэшированная кластеризованная матрица.
  /// Перестраивается только при изменении исходной матрицы или
  /// при включении/выключении кластеризации.
  CorrelationMatrix? _clusteredMatrix;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Создание начального маппера на основе текущих настроек
    _currentMapper = _createMapper();
    _previousMapper = _currentMapper; // Начальное состояние без анимации
  }

  @override
  void didUpdateWidget(covariant HeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Проверяем, изменились ли параметры, влияющие на цветовую схему
    if (oldWidget.palette != widget.palette ||
        oldWidget.segments != widget.segments ||
        oldWidget.colorMode != widget.colorMode) {
      // Сохраняем текущий маппер как предыдущий для анимации перехода
      _previousMapper = _currentMapper;

      // Создаем новый маппер с обновленными настройками
      _currentMapper = _createMapper();

      // Запускаем анимацию перехода от старой цветовой схемы к новой
      _controller.forward(from: 0);
    }

    // При изменении состояния кластеризации сбрасываем кэш,
    // чтобы при следующем обращении матрица была перекластеризована
    if (oldWidget.clusterEnabled != widget.clusterEnabled) {
      _clusteredMatrix = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Проверка на пустую матрицу - показываем информационное сообщение
    if (widget.matrix.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildHeatmap(constraints.biggest),
            ),
            HeatmapLegend(
              mapper: _currentMapper,
              min: -1,
              max: 1,
              segments: widget.segments,
            ),
          ],
        );
      },
    );
  }

  /// Создание маппера цветов на основе текущих настроек.
  ///
  /// Поддерживает два режима:
  /// - [HeatmapColorMode.discrete]: равномерные сегменты с четкими границами
  ///   (полезно для выявления точных значений)
  /// - [HeatmapColorMode.gradient]: плавный переход между цветами
  ///   (лучше для визуального восприятия общей структуры)
  HeatmapColorMapper _createMapper() {
    switch (widget.colorMode) {
      case HeatmapColorMode.discrete:
        // Получаем базовые цвета для выбранной палитры
        final base = HeatmapPaletteFactory.baseColors(widget.palette);

        return DiscreteColorMapper(
          min: -1,
          max: 1,
          segments: widget.segments,
          baseColors: base,
        );

      case HeatmapColorMode.gradient:
        return GradientColorMapper(
          paletteType: widget.palette,
        );
    }
  }

  /// Получение актуальной матрицы для отображения.
  ///
  /// Возвращает либо исходную матрицу, либо кластеризованную,
  /// в зависимости от настройки [clusterEnabled].
  /// 
  /// Результат кластеризации кэшируется для оптимизации производительности,
  /// так как операция кластеризации может быть вычислительно затратной
  /// для больших матриц.
  CorrelationMatrix _getDisplayMatrix() {
    if (!widget.clusterEnabled) return widget.matrix;

    // Ленивая инициализация: кластеризуем только при первом запросе
    _clusteredMatrix ??= CorrelationClusterer.cluster(widget.matrix);

    return _clusteredMatrix!;
  }

  /// Построение виджета тепловой карты с поддержкой масштабирования.
  ///
  /// Использует [InteractiveViewer] для обеспечения:
  /// - Панорамирования (перетаскивания) по большой матрице
  /// - Масштабирования жестами или двойным щелчком
  /// - Плавного скроллинга
  ///
  /// Также реализует интерактивную подсветку ячеек при наведении мыши
  /// (для десктопных и веб-версий).
  Widget _buildHeatmap(Size viewport) {
    final matrix = _getDisplayMatrix();

    final int n = matrix.size;

    final cellSize = (viewport.width / n).clamp(20.0, 80.0);

    final totalSize = n * cellSize;

    final showValues = cellSize > 35;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _zoomController,
          constrained: false,
          minScale: 0.5, // Минимальное увеличение
          maxScale: 5.0, // Максимальное увеличение
          boundaryMargin: const EdgeInsets.all(8), // Отступы от границ для удобства

          child: MouseRegion(
            // Отслеживание мыши для интерактивной подсветки
            onHover: (event) {
              final localPos = event.localPosition;

              // Вычисляем индекс ячейки под курсором.
              // Вычитаем cellSize для учета отступа под подписи осей,
              // который добавляется в HeatmapPainter.
              final axisOffset = widget.showAxisLabels ? cellSize : 0;
              final row = ((localPos.dy - axisOffset) / cellSize).floor();
              final col = ((localPos.dx - axisOffset) / cellSize).floor();

              // Проверяем, что курсор находится в пределах матрицы
              if (row >= 0 && row < n && col >= 0 && col < n) {
                if (row != hoverRow || col != hoverCol) {
                  setState(() {
                    hoverRow = row;
                    hoverCol = col;
                  });
                }
              } else {
                if (hoverRow != null) {
                  setState(() {
                    hoverRow = null;
                    hoverCol = null;
                  });
                }
              }
            },
            // Сброс подсветки при уходе мыши с виджета
            onExit: (_) {
              setState(() {
                hoverRow = null;
                hoverCol = null;
              });
            },

            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return CustomPaint(
                  size: Size(totalSize, totalSize),
                  painter: HeatmapPainter(
                    matrix: matrix,
                    colorMapper: _currentMapper,
                    previousMapper: _previousMapper,
                    animationValue: _controller.value,
                    cellSize: cellSize,
                    showValues: showValues,
                    showAxisLabels: widget.showAxisLabels,
                    triangleMode: widget.triangleMode,
                    hoverRow: hoverRow,
                    hoverCol: hoverCol,
                  ),
                );
              },
            ),
          ),
        ),

        // Кнопка сброса масштаба
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            elevation: 3,
            child: IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: () {
                _zoomController.value = Matrix4.identity();
              },
              tooltip: 'Сбросить масштаб',
            ),
          ),
        ),
      ],
    );
  }
}