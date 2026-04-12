import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector4;
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import '../painter/heatmap_painter.dart';
import 'heatmap_legend.dart';

/// Интерактивная тепловая карта с поддержкой масштабирования, анимации и кастомизации.
///
/// Принимает подготовленные данные [data] и конфигурацию [config].
/// Обеспечивает:
/// - Масштабирование и панорамирование через [InteractiveViewer]
/// - Подсветку ячеек при наведении мыши
/// - Плавную анимацию при изменении цветовой схемы
/// - Легенду под картой
class Heatmap extends StatefulWidget {
  /// Данные для отображения (обязательно).
  final HeatmapData data;

  /// Конфигурация отображения.
  final HeatmapConfig config;

  /// Контроллер для внешнего управления (сброс зума и т.д.).
  final HeatmapController? controller;

  /// Виджет, отображаемый во время вычислений (если данные ещё не готовы).
  final WidgetBuilder? loadingBuilder;

  /// Виджет, отображаемый при ошибке.
  final WidgetBuilder? errorBuilder;

  const Heatmap({
    super.key,
    required this.data,
    this.config = const HeatmapConfig(),
    this.controller,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> with SingleTickerProviderStateMixin {
  late HeatmapData _displayData;
  late HeatmapConfig _effectiveConfig;
  late HeatmapColorMapper _currentMapper;
  late HeatmapColorMapper _previousMapper;
  late AnimationController _animController;

  final TransformationController _zoomController = TransformationController();
  Matrix4? _lastMatrix;
  Rect? _visibleRect;

  int? _hoverRow;
  int? _hoverCol;
  HoverRange? _hoverRange;

  OverlayEntry? _tooltipEntry;
  final GlobalKey _heatmapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _displayData = widget.data;
    _effectiveConfig = widget.config;
    _currentMapper = _createMapper(_effectiveConfig);
    _previousMapper = _currentMapper;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant Heatmap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если данные изменились
    if (oldWidget.data != widget.data) {
      setState(() {
        _displayData = widget.data;
        // Сброс кэша visibleRect при смене данных
        _visibleRect = null;
        _lastMatrix = null;
      });
      _previousMapper = _currentMapper;
      _currentMapper = _createMapper(_effectiveConfig);
      _hideTooltip();
    }

    // Если конфигурация изменилась
    if (oldWidget.config != widget.config) {
      final newConfig = widget.config;
      setState(() {
        _effectiveConfig = newConfig;
        _previousMapper = _currentMapper;
        _currentMapper = _createMapper(newConfig);
      });
      // Запускаем анимацию только если изменились параметры, влияющие на цвет
      if (_shouldAnimateColorChange(oldWidget.config, newConfig)) {
        _animController.forward(from: 0.0);
      } else {
        _animController.value = 0.0;
      }
      // Если тултип отображался, пересоздаём с новым билдером
      if (_tooltipEntry != null) {
        _hideTooltip();
        if (_hoverRow != null && _hoverCol != null) {
          _showTooltip();
        }
      }
    }

    // Обновляем контроллер
    widget.controller?._attach(this);
  }

  bool _shouldAnimateColorChange(HeatmapConfig oldC, HeatmapConfig newC) {
    return oldC.palette != newC.palette ||
        oldC.colorMode != newC.colorMode ||
        oldC.segments != newC.segments;
  }

  @override
  void dispose() {
    _hideTooltip();
    widget.controller?._detach();
    _animController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  HeatmapColorMapper _createMapper(HeatmapConfig cfg) {
    final paletteColors = HeatmapPaletteFactory.baseColors(cfg.palette);
    final min = _displayData.min;
    final max = _displayData.max;

    if (cfg.colorMode == HeatmapColorMode.discrete) {
      return DiscreteColorMapper(
        min: min,
        max: max,
        segments: cfg.segments,
        baseColors: paletteColors,
      );
    } else {
      return GradientColorMapper(
        paletteType: cfg.palette,
        min: min,
        max: max,
      );
    }
  }

  void _updateVisibleRect({
    required double axisOffset,
    required double cellWidth,
    required double cellHeight,
    required int colCount,
    required int rowCount,
  }) {
    final matrix = _zoomController.value;
    if (_lastMatrix == matrix) return;
    _lastMatrix = matrix;

    final size = context.size;
    if (size == null) return;

    final inverted = Matrix4.inverted(matrix);
    final topLeft = Vector4(0, 0, 0, 1);
    final bottomRight = Vector4(size.width, size.height, 0, 1);
    final topLeftTransformed = inverted.transform(topLeft);
    final bottomRightTransformed = inverted.transform(bottomRight);

    final left = topLeftTransformed.x;
    final top = topLeftTransformed.y;
    final right = bottomRightTransformed.x;
    final bottom = bottomRightTransformed.y;

    final startCol = ((left - axisOffset) / cellWidth)
        .floor()
        .clamp(0, colCount - 1);
    final endCol = ((right - axisOffset) / cellWidth)
        .ceil()
        .clamp(0, colCount - 1);
    final startRow = ((top - axisOffset) / cellHeight)
        .floor()
        .clamp(0, rowCount - 1);
    final endRow = ((bottom - axisOffset) / cellHeight)
        .ceil()
        .clamp(0, rowCount - 1);

    setState(() {
      _visibleRect = Rect.fromLTRB(
        startCol.toDouble(),
        startRow.toDouble(),
        endCol.toDouble(),
        endRow.toDouble(),
      );
    });
  }

  void _handleHover(
    Offset localPosition,
    double axisOffset,
    double cellWidth,
    double cellHeight,
    int rowCount,
    int colCount,
  ) {
    final row = ((localPosition.dy - axisOffset) / cellHeight).floor();
    final col = ((localPosition.dx - axisOffset) / cellWidth).floor();

    if (row >= 0 && row < rowCount && col >= 0 && col < colCount) {
      if (row != _hoverRow || col != _hoverCol) {
        setState(() {
          _hoverRow = row;
          _hoverCol = col;
        });
        _showTooltip();
      }
    } else {
      if (_hoverRow != null) {
        setState(() {
          _hoverRow = null;
          _hoverCol = null;
        });
        _hideTooltip();
      }
    }
  }

  void _onLegendHover(HoverRange? range) {
    setState(() => _hoverRange = range);
  }

  void _showTooltip() {
    if (_effectiveConfig.cellTooltipBuilder == null) return;
    if (_hoverRow == null || _hoverCol == null) return;

    _hideTooltip();

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        final cell = HeatmapCell(
          value: _displayData.values[_hoverRow!][_hoverCol!],
          rowLabel: _displayData.rowLabels[_hoverRow!],
          colLabel: _displayData.columnLabels[_hoverCol!],
          rowIndex: _hoverRow!,
          colIndex: _hoverCol!,
        );
        return _TooltipPositioner(
          heatmapKey: _heatmapKey,
          row: _hoverRow!,
          col: _hoverCol!,
          rowCount: _displayData.rowLabels.length,
          colCount: _displayData.columnLabels.length,
          axisOffset: _getAxisOffset(),
          child: _effectiveConfig.cellTooltipBuilder!(context, cell),
        );
      },
    );

    Overlay.of(context).insert(_tooltipEntry!);
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  double _getAxisOffset() => _effectiveConfig.showAxisLabels ? 40.0 : 0.0;

  // Метод для сброса зума (вызывается через контроллер)
  void resetZoom() {
    _zoomController.value = Matrix4.identity();
    _visibleRect = null;
    _lastMatrix = null;
  }

  @override
  Widget build(BuildContext context) {
    final rowCount = _displayData.rowLabels.length;
    final colCount = _displayData.columnLabels.length;

    if (rowCount == 0 || colCount == 0) {
      return Center(
        child: widget.errorBuilder?.call(context) ??
            const Text('Нет данных для отображения'),
      );
    }

    final axisOffset = _getAxisOffset();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - axisOffset - 16;
        final availableHeight = constraints.maxHeight - axisOffset - 60;

        double cellWidth = availableWidth / colCount;
        double cellHeight = availableHeight / rowCount;

        cellWidth = cellWidth.clamp(0.0, 200.0);
        cellHeight = cellHeight.clamp(0.0, 200.0);

        final effectiveShowValues =
            _effectiveConfig.showValues ;

        final totalWidth = colCount * cellWidth + axisOffset;
        final totalHeight = rowCount * cellHeight + axisOffset;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InteractiveViewer(
                transformationController: _zoomController,
                onInteractionUpdate: (_) => _updateVisibleRect(
                  axisOffset: axisOffset,
                  cellHeight: cellHeight,
                  cellWidth: cellWidth,
                  colCount: colCount,
                  rowCount: rowCount,
                ),
                constrained: false,
                minScale: _effectiveConfig.minScale,
                maxScale: _effectiveConfig.maxScale,
                boundaryMargin: const EdgeInsets.all(8),
                child: MouseRegion(
                  onHover: (event) {
                    _handleHover(
                      event.localPosition,
                      axisOffset,
                      cellWidth,
                      cellHeight,
                      rowCount,
                      colCount,
                    );
                  },
                  onExit: (_) {
                    setState(() {
                      _hoverRow = null;
                      _hoverCol = null;
                    });
                    _hideTooltip();
                  },
                  child: Container(
                    key: _heatmapKey,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (_, __) {
                        return CustomPaint(
                          size: Size(totalWidth, totalHeight),
                          painter: HeatmapPainter(
                            data: _displayData,
                            colorMapper: _currentMapper,
                            previousMapper: _previousMapper,
                            animationValue: _animController.value,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            config: _effectiveConfig.copyWith(
                              showValues: effectiveShowValues,
                            ),
                            axisOffset: axisOffset,
                            hoverRow: _hoverRow,
                            hoverCol: _hoverCol,
                            hoverRange: _hoverRange,
                            visibleRect: _visibleRect,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: HeatmapLegend(
                mapper: _currentMapper,
                colorMode: _effectiveConfig.colorMode,
                min: _displayData.min,
                max: _displayData.max,
                segments: _effectiveConfig.segments,
                onHover: _onLegendHover,
                cellTooltipBuilder: _effectiveConfig.legendTooltipBuilder,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TooltipPositioner extends StatelessWidget {
  final GlobalKey heatmapKey;
  final int row;
  final int col;
  final int rowCount;
  final int colCount;
  final double axisOffset;
  final Widget child;

  const _TooltipPositioner({
    required this.heatmapKey,
    required this.row,
    required this.col,
    required this.rowCount,
    required this.colCount,
    required this.axisOffset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final renderBox =
        heatmapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final heatmapSize = renderBox.size;
    final heatmapOffset = renderBox.localToGlobal(Offset.zero);

    final cellWidth = (heatmapSize.width - axisOffset) / colCount;
    final cellHeight = (heatmapSize.height - axisOffset) / rowCount;

    final cellLeft = heatmapOffset.dx + axisOffset + col * cellWidth;
    final cellTop = heatmapOffset.dy + axisOffset + row * cellHeight;

    return Positioned(
      left: cellLeft + cellWidth + 8,
      top: cellTop + cellHeight / 2,
      child: FractionalTranslation(
        translation: const Offset(0, -0.5),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

/// Контроллер для внешнего управления тепловой картой.
class HeatmapController {
  _HeatmapState? _state;

  void _attach(_HeatmapState state) => _state = state;
  void _detach() => _state = null;

  /// Сбрасывает масштаб и панорамирование к исходному состоянию.
  void resetZoom() => _state?.resetZoom();
}