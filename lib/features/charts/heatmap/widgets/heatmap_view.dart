import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_legend.dart';

import '../model/correlation_clusterer.dart';
import '../model/correlation_matrix.dart';
import '../color/heatmap_color_mapper.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_state.dart';
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
  /// Данные для отображения тепловой карты, включая значения и метки
  final HeatmapData heatmapData;

  /// Состояние тепловой карты, содержащее настройки отображения
  final HeatmapState state;

  /// {@macro heatmap_view}
  const HeatmapView({
    super.key,
    required this.heatmapData,
    required this.state,
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

  /// Кэш последних параметров, влияющих на цветовую схему
  HeatmapPalette? _lastPalette;

  /// Кэш последнего количества сегментов для дискретного режима
  int? _lastSegments;

  /// Кэш последнего режима отображения цветов
  HeatmapColorMode? _lastMode;

  /// Данные, подготовленные для отображения (после кластеризации, сортировки, нормализации)
  late HeatmapData _displayData;

  /// Минимальное и максимальное значение в отображаемых данных для настройки цветовой шкалы
  late double _currentMin;
  late double _currentMax;
  
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _recomputeDisplayData();
    // Создание начального маппера на основе текущих настроек
    _currentMapper = _createMapper();
    _previousMapper = _currentMapper; // Начальное состояние без анимации

    _lastPalette = widget.state.palette;
    _lastSegments = widget.state.segments;
    _lastMode = widget.state.colorMode;

    
  }

  @override
  void didUpdateWidget(covariant HeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Проверяем изменения, которые влияют на данные / цвета
    if (oldWidget.state.normalizeMode != widget.state.normalizeMode ||
        oldWidget.state.sortX != widget.state.sortX ||
        oldWidget.state.sortY != widget.state.sortY ||
        oldWidget.state.clusterEnabled != widget.state.clusterEnabled ||
        oldWidget.heatmapData != widget.heatmapData) {
      _recomputeDisplayData();
    }

    // Проверяем, изменились ли параметры, влияющие на цветовую схему
    if (_lastPalette != widget.state.palette ||
        _lastSegments != widget.state.segments ||
        _lastMode != widget.state.colorMode) {
      // Сохраняем текущий маппер как предыдущий для анимации перехода
      _previousMapper = _currentMapper;

      // Создаем новый маппер с обновленными настройками
      _currentMapper = _createMapper();

      // Запускаем анимацию перехода от старой цветовой схемы к новой
      _controller.forward(from: 0);

      _lastPalette = widget.state.palette;
      _lastSegments = widget.state.segments;
      _lastMode = widget.state.colorMode;
    }

    // При изменении состояния кластеризации сбрасываем кэш,
    // чтобы при следующем обращении матрица была перекластеризована
    if (oldWidget.state.clusterEnabled != widget.state.clusterEnabled) {
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
    if (widget.heatmapData.rowLabels.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных для отображения (выбраны две числовые колонки?)',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    // Проверка на пустую матрицу - показываем информационное сообщение
    if (widget.heatmapData.values.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (widget.heatmapData.rowLabels.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных для отображения (выбраны две числовые колонки?)',
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
              segments: widget.state.segments,
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
    final paletteColors = HeatmapPaletteFactory.baseColors(widget.state.palette);

    if (widget.state.colorMode == HeatmapColorMode.discrete) {
      // Здесь можно позже добавить логику scaleType == quantile
      return DiscreteColorMapper(
        min: _currentMin,
        max: _currentMax,
        segments: widget.state.segments,
        baseColors: paletteColors,
      );
    } else {
      return GradientColorMapper(
        paletteType: widget.state.palette,
        min: _currentMin,
        max: _currentMax,
      );
    }
  }

  /// Пересчет данных для отображения на основе текущих настроек.
  ///
  /// Выполняет следующие шаги:
  /// 1. Кластеризация (если включена) — меняет порядок строк
  /// 2. Сортировка (после кластеризации, т.к. она тоже сортирует)
  /// 3. Нормализация (после сортировки — логичнее для интерпретации)
  void _recomputeDisplayData() {
    HeatmapData data = widget.heatmapData;

    // 1. кластеризация (если включена) — меняет порядок строк
    if (widget.state.clusterEnabled &&
      widget.state.xColumn == null &&
      widget.state.yColumn == null) {
      data = CorrelationClusterer.clusterHeatmapData(data);
    }

    // 2. сортировка
    data = data.sortRows(widget.state.sortX);
    data = data.sortCols(widget.state.sortY);

    // 3. нормализация
    data = data.normalize(widget.state.normalizeMode);

    _displayData = data;
    _currentMin = data.min;
    _currentMax = data.max;

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
    final rowCount = _displayData.rowLabels.length;
    final colCount = _displayData.columnLabels.length;
    debugPrint('Кол-во строк: $rowCount, Кол-во столбцов: $colCount');
    final cellSizeByWidth = viewport.width / colCount;
    final cellSizeByHeight = viewport.height / rowCount;

    final cellSize = min(cellSizeByWidth, cellSizeByHeight).clamp(20.0, 80.0);

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
              final axisOffset = widget.state.showAxisLabels ? cellSize : 0;
              final row = ((localPos.dy - axisOffset) / cellSize).floor();
              final col = ((localPos.dx - axisOffset) / cellSize).floor();

              // Проверяем, что курсор находится в пределах матрицы
              if (row >= 0 && row < rowCount && col >= 0 && col < colCount) {
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
                  size: Size(colCount * cellSize, rowCount * cellSize),
                  painter: HeatmapPainter(
                    data: _displayData,
                    colorMapper: _currentMapper,
                    previousMapper: _previousMapper,
                    animationValue: _controller.value,
                    cellSize: cellSize,
                    showValues: showValues,
                    showAxisLabels: false,
                    triangleMode: widget.state.triangleMode,
                    hoverRow: hoverRow,
                    hoverCol: hoverCol,
                    showPercentage: widget.state.showPercentage,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}