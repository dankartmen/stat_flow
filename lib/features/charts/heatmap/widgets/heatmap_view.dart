import 'dart:math' show min, max;
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_legend.dart';

import '../../../../core/dataset/dataset.dart';
import '../calculator/heatmap_data_builder.dart';
import '../model/correlation_clusterer.dart';
import '../color/heatmap_color_mapper.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_state.dart';
import '../model/hover_range.dart';
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
  final Dataset dataset;

  /// Состояние тепловой карты, содержащее настройки отображения
  final HeatmapState state;

  /// {@macro heatmap_view}
  const HeatmapView({
    super.key,
    required this.dataset,
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

  /// Данные, подготовленные для отображения (после кластеризации, сортировки, нормализации)
  late HeatmapData? _displayData;

  /// Текущий минимум для цветовой шкалы
  double? _currentMin;

  /// Текущий максимум для цветовой шкалы
  double? _currentMax;

  /// Кэш ключа данных для оптимизации повторных вычислений
  String? _currentDataKey;

  /// Future для асинхронного вычисления данных  
  Future<HeatmapData>? _computeFuture;
  /// Диапазон значений, соответствующий наведению на легенду.
  /// Используется для подсветки ячеек с близкими значениями.
  HoverRange? _hoverRange;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _startComputation();
  }

  @override
  void didUpdateWidget(covariant HeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Проверяем изменения, которые влияют на данные / цвета
    if (widget.state != oldWidget.state ||
        widget.dataset != oldWidget.dataset) {
      _startComputation();
    }

    // Проверяем, изменились ли параметры, влияющие на цветовую схему
    if (oldWidget.state.palette != widget.state.palette ||
        oldWidget.state.segments != widget.state.segments ||
        oldWidget.state.colorMode != widget.state.colorMode) {
      if (_displayData != null) {
        _previousMapper = _currentMapper;
        _currentMapper = _createMapper();
        _controller.forward(from: 0);
      }
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
    if (_displayData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildHeatmap();
  }

  /// Обработчик готовности данных. Устанавливает [_displayData] и обновляет мапперы цветов.
  void _onDataReady(HeatmapData data) {
      if (!mounted) return;
      setState(() {
        _displayData = data;
        _currentMapper = _createMapper();
        _previousMapper = _currentMapper; // сброс анимации
        _controller.value = 0;
      });
    }

  /// Запускает вычисление данных тепловой карты.
  ///
  /// Если данные уже вычислены для текущего ключа, пропускает.
  /// В противном случае вычисляет синхронно (для корреляции) или асинхронно (для выбранных осей).
  void _startComputation() {
    final key = _computeKey();
    if (_currentDataKey == key && _displayData != null) return;
    _currentDataKey = key;

    // Сбрасываем текущие данные
    setState(() {
      _displayData = null;
      _computeFuture = null;
    });

    // Режим корреляции (обе оси не выбраны) – строим синхронно
    if (widget.state.useCorrelation) {
      final matrix = widget.dataset.corr();
      var data = HeatmapData.fromCorrelation(matrix);
      data = _applyTransformations(data);
      _onDataReady(data);
      setState(() => _displayData = data);
      return;
    }

    

    // Режим выбранных осей – асинхронно
    _computeFuture = HeatmapDataBuilder.computeAsync(
      dataset: widget.dataset,
      state: widget.state,
    );
    _computeFuture!.then(_onDataReady).catchError((error) {
      if (mounted) {
        _onDataReady(HeatmapData(rowLabels: [], columnLabels: [], values: []));
      }
    });
  }
  
  /// Применяет к данным все трансформации: кластеризацию, сортировку, нормализацию, проценты.
  HeatmapData _applyTransformations(HeatmapData data) {
    // Кластеризация только для корреляционной матрицы
    if (widget.state.clusterEnabled &&
        widget.state.useCorrelation) {
      data = CorrelationClusterer.clusterHeatmapData(data);
    }

    // Сортировка
    if (widget.state.sortX != SortMode.none) {
      data = data.sortRows(widget.state.sortX);
    }
    if (widget.state.sortY != SortMode.none) {
      data = data.sortCols(widget.state.sortY);
    }

    // Нормализация
    if (widget.state.normalizeMode != NormalizeMode.none) {
      data = data.normalize(widget.state.normalizeMode);
    }

    // Проценты
    if (widget.state.percentageMode != PercentageMode.none) {
      data = data.toPercentages(widget.state.percentageMode);
    }

    return data;
  }

  /// Генерирует ключ для кэширования данных на основе настроек
  String _computeKey() {
    return '${widget.state.xColumn}_${widget.state.yColumn}_${widget.state.useCorrelation}_'
        '${widget.state.aggregationType}_${widget.state.clusterEnabled}_'
        '${widget.state.sortX}_${widget.state.sortY}_'
        '${widget.state.normalizeMode}_${widget.state.percentageMode}';
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
    final min = _displayData?.min ?? -1.0;
    final max = _displayData?.max ?? 1.0;
    if (widget.state.colorMode == HeatmapColorMode.discrete) {      
      return DiscreteColorMapper(
        min: min,
        max: max,
        segments: widget.state.segments,
        baseColors: paletteColors,
      );
    } else {
      return GradientColorMapper(
        paletteType: widget.state.palette,
        min: min,
        max: max,
      );
    }
  }

  /// Обработчик наведения на легенду. Обновляет [_hoverRange] для подсветки ячеек.
  void _onLegendHover(HoverRange? range) {
    setState(() => _hoverRange = range);
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
  Widget _buildHeatmap() {
    final rowCount = _displayData!.rowLabels.length;
    final colCount = _displayData!.columnLabels.length;
    if (rowCount == 0 || colCount == 0) {
      return const Center(child: Text('Нет данных для отображения'));
    }
    final axisOffset = widget.state.showAxisLabels ? 40.0 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints){
        final availableWidth = constraints.maxWidth - axisOffset - 16; // Учитываем отступы и место для легенды
        final availableHeight = constraints.maxHeight - axisOffset - 60; // Учитываем место для легенды
      
        double cellSizeByWidth = availableWidth / colCount;
        double cellSizeByHeight = availableHeight / rowCount;

        cellSizeByWidth = cellSizeByWidth.clamp(0.0, 200.0);
        cellSizeByHeight = cellSizeByHeight.clamp(0.0, 200.0);

        final showValues = min(cellSizeByWidth, cellSizeByHeight) > 35;

        final totalWidth = colCount * cellSizeByWidth + axisOffset;
        final totalHeight = rowCount * cellSizeByHeight + axisOffset;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InteractiveViewer(
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
                    final row = ((localPos.dy - axisOffset) / cellSizeByHeight).floor();
                    final col = ((localPos.dx - axisOffset) / cellSizeByWidth).floor();
          
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
                        size: Size(totalWidth, totalHeight),
                        painter: HeatmapPainter(
                          data: _displayData!,
                          axisOffset: axisOffset,
                          colorMapper: _currentMapper,
                          previousMapper: _previousMapper,
                          animationValue: _controller.value,
                          cellWidth: cellSizeByWidth,
                          cellHeight: cellSizeByHeight,
                          showValues: showValues,
                          showAxisLabels: false,
                          triangleMode: widget.state.triangleMode,
                          hoverRow: hoverRow,
                          hoverCol: hoverCol,
                          hoverRange: _hoverRange,
                          percentageMode: widget.state.percentageMode,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            HeatmapLegend(
              mapper: _currentMapper,
              min: _displayData!.min,
              max: _displayData!.max,
              segments: widget.state.segments,
              onHover: _onLegendHover,
              colorMode: widget.state.colorMode,
            ),
          ],
        );
      }
    );
  }
}