import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector4;
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import '../painter/heatmap_painter.dart';
import 'heatmap_legend.dart';

/// {@template heatmap_canvas._axis_metrics}
/// Вспомогательная структура для хранения рассчитанных отступов осей.
/// {@endtemplate}
class _AxisMetrics {
  final double offset;
  final double bottomSpace;

  const _AxisMetrics({required this.offset, required this.bottomSpace});
}

/// {@template heatmap_canvas.heatmap}
/// Интерактивная тепловая карта с поддержкой масштабирования, анимации и кастомизации.
///
/// Принимает подготовленные данные [data] и конфигурацию [config].
/// Обеспечивает:
/// - Масштабирование и панорамирование через [InteractiveViewer]
/// - Подсветку ячеек при наведении мыши
/// - Плавную анимацию при изменении цветовой схемы
/// - Легенду под картой
/// - Автоматическое усечение подписей осей
/// - Умное позиционирование тултипов
/// {@endtemplate}
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

  /// {@macro heatmap_canvas.heatmap}
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

/// Состояние виджета [Heatmap].
class _HeatmapState extends State<Heatmap> with SingleTickerProviderStateMixin {
  late HeatmapData _displayData;
  late HeatmapConfig _effectiveConfig;
  late HeatmapColorMapper _currentMapper;
  late HeatmapColorMapper _previousMapper;
  late AnimationController _animController;

  final TransformationController _zoomController = TransformationController();
  Matrix4? _lastMatrix;
  Rect? _visibleRect;
  double? _lastAxisOffset;

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

  /// Создаёт маппер цветов на основе текущей конфигурации и диапазона данных.
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

  /// Обновляет видимую область матрицы на основе текущей трансформации InteractiveViewer.
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

    final startCol =
        ((left - axisOffset) / cellWidth).floor().clamp(0, colCount - 1);
    final endCol =
        ((right - axisOffset) / cellWidth).ceil().clamp(0, colCount - 1);
    final startRow =
        ((top - axisOffset) / cellHeight).floor().clamp(0, rowCount - 1);
    final endRow =
        ((bottom - axisOffset) / cellHeight).ceil().clamp(0, rowCount - 1);

    setState(() {
      _visibleRect = Rect.fromLTRB(
        startCol.toDouble(),
        startRow.toDouble(),
        endCol.toDouble(),
        endRow.toDouble(),
      );
    });
  }

  /// Обрабатывает наведение мыши на сетку тепловой карты.
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
          _lastAxisOffset = axisOffset;
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
    if (_lastAxisOffset == null) return;

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
          axisOffset: _lastAxisOffset!,
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

  TextStyle _axisTextStyle(double cellWidth, double cellHeight) {
    if (_effectiveConfig.axisTextStyle != null) {
      return _effectiveConfig.axisTextStyle!;
    }

    final baseSize = math.min(cellWidth, cellHeight) * 0.25;
    return TextStyle(
      fontSize: math.min(14.0, math.max(10.0, baseSize)),
      color: Colors.black87,
    );
  }

  /// Вычисляет оптимальные отступы для подписей осей с учётом максимальной длины меток.
  _AxisMetrics _computeAxisMetrics(
    BoxConstraints constraints,
    int rowCount,
    int colCount,
  ) {
    if (!_effectiveConfig.showAxisLabels) {
      return const _AxisMetrics(offset: 16.0, bottomSpace: 0.0);
    }

    const outerPadding = 12.0;
    final bottomReserve = widget.config.legendPosition == LegendPosition.bottom
        ? 88.0
        : 16.0;

    double axisOffset = 48.0;
    double bottomSpace = 24.0;
    for (int i = 0; i < 4; i++) {
      final availableWidth =
          (constraints.maxWidth - axisOffset - outerPadding).clamp(0.0, double.infinity);
      final availableHeight =
          (constraints.maxHeight - axisOffset - bottomReserve - bottomSpace)
              .clamp(0.0, double.infinity);

      final cellWidth = colCount > 0
          ? (availableWidth / colCount).clamp(28.0, 200.0)
          : 28.0;
      final cellHeight = rowCount > 0
          ? (availableHeight / rowCount).clamp(28.0, 200.0)
          : 28.0;

      final textStyle = _axisTextStyle(cellWidth, cellHeight);
      final maxRowLabelWidth = _displayData.rowLabels
          .map((label) => _measureText(_shortenRowLabel(label), textStyle).width)
          .fold(0.0, math.max);
      final maxColLabelHeight = _displayData.columnLabels
          .map((label) => _rotatedTextSize(
                _shortenColumnLabel(label, textStyle, cellWidth),
                textStyle,
                _effectiveConfig.axisLabelRotation,
              ).height)
          .fold(0.0, math.max);

      final newOffset = math.max(48.0, maxRowLabelWidth + 16.0);
      final newBottomSpace = math.max(24.0, maxColLabelHeight + 12.0);

      if ((axisOffset - newOffset).abs() < 1.0 &&
          (bottomSpace - newBottomSpace).abs() < 1.0) {
        axisOffset = newOffset;
        bottomSpace = newBottomSpace;
        break;
      }
      axisOffset = newOffset;
      bottomSpace = newBottomSpace;
    }
    return _AxisMetrics(offset: axisOffset, bottomSpace: bottomSpace);
  }

  String _shortenRowLabel(String label) {
    if (label.length <= 20) return label;
    return '${label.substring(0, 17)}…';
  }

  String _truncateText(String text, TextStyle style, double maxWidth) {
    final fullWidth = _measureText(text, style).width;
    if (fullWidth <= maxWidth) return text;

    var low = 0;
    var high = text.length;
    while (low < high) {
      final mid = ((low + high + 1) / 2).floor();
      final candidate = '${text.substring(0, mid)}…';
      if (_measureText(candidate, style).width <= maxWidth) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    if (low <= 0) return '…';
    return '${text.substring(0, low)}…';
  }

  String _shortenColumnLabel(
    String label,
    TextStyle style,
    double cellWidth,
  ) {
    if (label.length <= 20) return _truncateText(label, style, cellWidth * 0.9);
    return _truncateText(label, style, cellWidth * 0.9);
  }

  Size _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return painter.size;
  }

  Size _rotatedTextSize(String text, TextStyle style, double rotation) {
    final size = _measureText(text, style);
    final angle = rotation.abs();
    final cosA = math.cos(angle).abs();
    final sinA = math.sin(angle).abs();
    return Size(
      size.width * cosA + size.height * sinA,
      size.height * cosA + size.width * sinA,
    );
  }

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

    const outerPadding = 12.0;
    final bottomReserve =
        widget.config.legendPosition == LegendPosition.bottom ? 88.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final axisMetrics = _computeAxisMetrics(constraints, rowCount, colCount);
        final axisOffset = axisMetrics.offset;
        final bottomLabelSpace = axisMetrics.bottomSpace;
        final availableWidth =
            (constraints.maxWidth - axisOffset - outerPadding).clamp(0.0, double.infinity);
        final availableHeight =
            (constraints.maxHeight - axisOffset - bottomReserve - bottomLabelSpace)
                .clamp(0.0, double.infinity);

        double cellWidth = colCount > 0 ? (availableWidth / colCount).clamp(28.0, 200.0) : 28.0;
        double cellHeight = rowCount > 0 ? (availableHeight / rowCount).clamp(28.0, 200.0) : 28.0;

        final effectiveShowValues = _effectiveConfig.showValues;

        final totalWidth = colCount * cellWidth + axisOffset;
        final totalHeight = rowCount * cellHeight + axisOffset + bottomLabelSpace;

        if (widget.config.legendPosition == LegendPosition.bottom) {
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
                              bottomLabelOffset: bottomLabelSpace,
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
                  legendTooltipBuilder: _effectiveConfig.legendTooltipBuilder,
                ),
              ),
            ],
          );
        } else {
          return Stack(
            children: [
              SizedBox.expand(
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
                              bottomLabelOffset: bottomLabelSpace,
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
              Positioned(
                top: 12,
                right: 12,
                child: SizedBox(
                  width: 220,
                  child: HeatmapLegend(
                    mapper: _currentMapper,
                    colorMode: _effectiveConfig.colorMode,
                    min: _displayData.min,
                    max: _displayData.max,
                    segments: _effectiveConfig.segments,
                    onHover: _onLegendHover,
                    legendTooltipBuilder: _effectiveConfig.legendTooltipBuilder,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

/// Виджет для умного позиционирования тултипа относительно ячейки.
class _TooltipPositioner extends StatefulWidget {
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
  State<_TooltipPositioner> createState() => _TooltipPositionerState();
}

class _TooltipPositionerState extends State<_TooltipPositioner> {
  Size? _tooltipSize;

  void _updateTooltipSize(Size size) {
    if (_tooltipSize != size) {
      setState(() {
        _tooltipSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final renderBox =
        widget.heatmapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final heatmapSize = renderBox.size;
    final heatmapOffset = renderBox.localToGlobal(Offset.zero);

    final cellWidth = (heatmapSize.width - widget.axisOffset) / widget.colCount;
    final cellHeight =
        (heatmapSize.height - widget.axisOffset) / widget.rowCount;

    final cellLeft =
        heatmapOffset.dx + widget.axisOffset + widget.col * cellWidth;
    final cellTop =
        heatmapOffset.dy + widget.axisOffset + widget.row * cellHeight;
    final cellCenter =
        Offset(cellLeft + cellWidth / 2, cellTop + cellHeight / 2);

    final heatmapRect = Rect.fromLTWH(
      heatmapOffset.dx,
      heatmapOffset.dy,
      heatmapSize.width,
      heatmapSize.height,
    );
    final margin = 8.0;
    final tooltipSize = _tooltipSize ?? const Size(160, 64);

    final cellRect = Rect.fromLTWH(cellLeft, cellTop, cellWidth, cellHeight);
    final availableRight = heatmapRect.right - cellRect.right - margin;
    final availableLeft = cellRect.left - heatmapRect.left - margin;
    final availableBelow = heatmapRect.bottom - cellRect.bottom - margin;
    final availableAbove = cellRect.top - heatmapRect.top - margin;

    Offset target;
    if (availableRight >= tooltipSize.width) {
      target = Offset(
          cellRect.right + margin, cellCenter.dy - tooltipSize.height / 2);
    } else if (availableLeft >= tooltipSize.width) {
      target = Offset(cellRect.left - tooltipSize.width - margin,
          cellCenter.dy - tooltipSize.height / 2);
    } else if (availableBelow >= tooltipSize.height) {
      target = Offset(
          cellCenter.dx - tooltipSize.width / 2, cellRect.bottom + margin);
    } else if (availableAbove >= tooltipSize.height) {
      target = Offset(cellCenter.dx - tooltipSize.width / 2,
          cellRect.top - tooltipSize.height - margin);
    } else {
      final fallbackLeft = (cellCenter.dx - tooltipSize.width / 2).clamp(
          heatmapRect.left + margin,
          heatmapRect.right - tooltipSize.width - margin);
      final fallbackTop = (cellCenter.dy - tooltipSize.height / 2).clamp(
          heatmapRect.top + margin,
          heatmapRect.bottom - tooltipSize.height - margin);
      target = Offset(fallbackLeft, fallbackTop);
    }

    final left = target.dx.clamp(
      heatmapRect.left + margin,
      heatmapRect.right - tooltipSize.width - margin,
    );
    final top = target.dy.clamp(
      heatmapRect.top + margin,
      heatmapRect.bottom - tooltipSize.height - margin,
    );

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: true,
        child: _MeasureSize(
          onChange: _updateTooltipSize,
          child: Material(
            color: Colors.transparent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Виджет, измеряющий размер своего потомка и сообщающий об изменениях.
class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({
    required Widget child,
    required this.onChange,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final size = child?.size ?? Size.zero;
    if (_lastSize != size) {
      _lastSize = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (size != _lastSize) return;
        onChange(size);
      });
    }
  }
}

/// {@template heatmap_canvas.heatmap_controller}
/// Контроллер для внешнего управления тепловой картой.
/// 
/// Позволяет программно сбрасывать масштаб и панорамирование.
/// {@endtemplate}
class HeatmapController {
  _HeatmapState? _state;

  void _attach(_HeatmapState state) => _state = state;
  void _detach() => _state = null;

  /// Сбрасывает масштаб и панорамирование к исходному состоянию.
  void resetZoom() => _state?.resetZoom();
}