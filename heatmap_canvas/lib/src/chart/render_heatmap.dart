import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import '../model/paint_holder.dart';
import '../model/touch_data.dart';
import '../painter/heatmap_painter.dart';
import '../utils/number_formatter.dart';

/// {@template render_heatmap.axis_metrics}
/// Структура, хранящая рассчитанные отступы со всех четырёх сторон.
///
/// Теперь отступы разделены явно:
/// - [left]   — место под подписи строк (row labels)
/// - [top]    — отступ сверху до первой строки ячеек (учитывает легенду)
/// - [right]  — резерв справа (обычно под легенду в topRight)
/// - [bottom] — место под подписи столбцов (column labels)
/// {@endtemplate}
class AxisMetrics {
  /// Отступ слева до начала ячеек и подписей строк
  final double left;

  /// Отступ сверху до первой строки ячеек
  final double top;

  /// Отступ справа (резерв под легенду или другие элементы)
  final double right;

  /// Отступ снизу под подписи столбцов
  final double bottom;

  const AxisMetrics({
    required this.left,
    required this.top,
    this.right = 0.0,
    required this.bottom,
  });

  /// Удобный конструктор для случая, когда showLabels = false
  const AxisMetrics.noLabels({
    double left = 12.0,
    double top = 12.0,
    double right = 0.0,
    double bottom = 0.0,
  }) : this(left: left, top: top, right: right, bottom: bottom);
}


/// {@template render_heatmap}
/// Рендер-объект для тепловой карты.
///
/// Отвечает за:
/// - Вычисление геометрии (размеры ячеек, отступы для осей)
/// - Отрисовку через [HeatmapPainter]
/// - Обработку событий наведения (hover) и касаний (tap/hover)
/// - Отображение тултипов при наведении на ячейки
/// - Анимацию переходов между наборами данных
/// - Управление курсором мыши в зависимости от состояния
/// {@endtemplate}
class RenderHeatmap extends RenderBox {
  // Приватные поля с документацией
  HeatmapData _data;
  HeatmapData _targetData;
  double _animationValue;
  HeatmapConfig _config;
  TextScaler _textScaler;
  
  // Кэшированные результаты геометрии (пересчитываются в performLayout)
  double _bottomLabelOffset = 0; // Отступ для нижних подписей столбцов
  double _cellWidth = 0;         // Ширина одной ячейки в пикселях
  double _cellHeight = 0;        // Высота одной ячейки в пикселях
  double _leftPadding = 0.0;     // место под подписи строк
  double _topPadding = 0.0;      // отступ сверху
  double _rightPadding = 0.0;    // отступ справа
  double _bottomPadding = 0.0;   // место под подписи столбцов



  // Кэш последней определённой ячейки для оптимизации hit testing
  ({int row, int col})? _cachedCell;
  Offset? _lastLocalPosition;

  // Состояние наведения
  int? _hoverRow;                // Индекс строки под курсором
  int? _hoverCol;                // Индекс столбца под курсором
  HoverRange? _hoverRange;       // Вычисленный диапазон наведения
  HoverRange? _externalHoverRange; // Внешний диапазон (из родителя)
  late HeatmapColorMapper _currentMapper; // Текущий маппер цветов
  late HeatmapColorMapper _targetMapper;  // Целевой маппер (для анимации)
  HeatmapTouchResponse? _hoverResponse;   // Данные о наведении для колбэков

  // Управление тултипами
  OverlayEntry? _tooltipEntry;
  HeatmapTouchResponse? _lastTooltipResponse;
  
  // Курсор мыши
  MouseCursor _resolvedCursor = SystemMouseCursors.basic;

  /// Контекст сборки, необходимый для доступа к Overlay при отображении тултипов.
  final BuildContext buildContext;

  RenderHeatmap({
    required this.buildContext,
    required HeatmapData data,
    required HeatmapData targetData,
    required double animationValue,
    required HeatmapConfig config,
    required TextScaler textScaler,
    required HoverRange? externalHoverRange
  }) : _data = data,
       _targetData = targetData,
       _animationValue = animationValue,
       _config = config,
       _textScaler = textScaler,
       _externalHoverRange = externalHoverRange{
        _currentMapper = _createMapper(config, data);
        _targetMapper = _currentMapper;
      }

  HeatmapData get data => _data;
  set data(HeatmapData value) {
    if (_data == value) return;
    _data = value;
    markNeedsLayout();
  }

  HeatmapConfig get config => _config;
  set config(HeatmapConfig value) {
    if (_config == value) return;
    _config = value;
    markNeedsLayout();
  }

  HeatmapData get targetData => _targetData;
  set targetData(HeatmapData value) {
    if (_targetData == value) return;
    _targetData = value;
    markNeedsPaint();
  }

  double get animationValue => _animationValue;
  set animationValue(double value) {
    if (_animationValue == value) return;
    _animationValue = value;
    markNeedsPaint();
  }


  TextScaler get textScaler => _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    markNeedsLayout();
  }

  set externalHoverRange(HoverRange? value) {
    if (_externalHoverRange == value) return;
    _externalHoverRange = value;
    markNeedsPaint();
  }

  int? get hoverRow => _hoverRow;
  int? get hoverCol => _hoverCol;
  HoverRange? get hoverRange => _hoverRange;
  MouseCursor get systemCursor => _resolvedCursor;
  
  HeatmapColorMapper _createMapper(HeatmapConfig cfg, HeatmapData d) {
    final paletteColors = HeatmapPaletteFactory.baseColors(
      cfg.palette,
      customColors: cfg.customPaletteColors,
    );

    if (cfg.colorMode == HeatmapColorMode.discrete) {
      return DiscreteColorMapper(
        min: d.min,
        max: d.max,
        segments: cfg.segments,
        baseColors: paletteColors,
      );
    } else {
      return GradientColorMapper(
        paletteType: cfg.palette,
        min: d.min,
        max: d.max,
      );
    }
  }
  
  void _updateTooltip(HeatmapTouchResponse? response) {
    // Если ответ не изменился, ничего не делаем
    if (_lastTooltipResponse == response) return;
    _lastTooltipResponse = response;

    // Удаляем старый тултип
    _tooltipEntry?.remove();
    _tooltipEntry = null;

    if (response == null || response.cell == null) return;

    final cell = response.cell!;
    final touchData = _config.touchData;
    final tooltipConfig = touchData.touchTooltipData;

    // Определяем билдер контента: сначала cellTooltipBuilder из config,
    // затем contentBuilder из tooltipConfig.
    Widget? tooltipContent;
    if (_config.cellTooltipBuilder != null) {
      tooltipContent = _config.cellTooltipBuilder!(buildContext, cell);
    } else if (tooltipConfig.contentBuilder != null) {
      tooltipContent = tooltipConfig.contentBuilder!(buildContext, cell);
    }

    if (tooltipContent == null) {
      // Стандартный тултип
      final formattedValue = _config.cellValueFormatter?.call(cell.value) 
          ?? formatHeatmapNumber(cell.value);
      final tooltipText = '${cell.rowLabel} × ${cell.colLabel}\n$formattedValue';
      tooltipContent = Container(
        padding: tooltipConfig.padding,
        decoration: BoxDecoration(
          color: tooltipConfig.backgroundColor ?? Colors.black87,
          borderRadius: tooltipConfig.borderRadius ?? BorderRadius.circular(4),
        ),
        child: Text(
          tooltipText,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }

    // Вычисляем положение тултипа
    final cellLeft = _leftPadding + cell.colIndex * _cellWidth;
    final cellTop = _topPadding + cell.rowIndex * _cellHeight;
    final cellCenter = Offset(cellLeft + _cellWidth / 2, cellTop + _cellHeight / 2);
    
    // Получаем глобальные координаты
    final globalOffset = localToGlobal(Offset.zero);
    final globalCellCenter = Offset(
      globalOffset.dx + cellCenter.dx,
      globalOffset.dy + cellCenter.dy,
    );
    final globalCellRect = Rect.fromLTWH(
      globalOffset.dx + cellLeft,
      globalOffset.dy + cellTop,
      _cellWidth,
      _cellHeight,
    );
    // Создаём OverlayEntry с позиционированием через LayoutBuilder или Positioned
    _tooltipEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _TooltipPositionDelegate(
              targetGlobalCenter: globalCellCenter,
              tooltipMargin: tooltipConfig.tooltipMargin,
              fitInsideHorizontally: tooltipConfig.fitInsideHorizontally,
              fitInsideVertically: tooltipConfig.fitInsideVertically,
              chartGlobalRect: Rect.fromLTWH(
                globalOffset.dx,
                globalOffset.dy,
                size.width,
                size.height,
              ),
              cellGlobalRect: globalCellRect
            ),
            child: tooltipContent,
          ),
        );
      },
    );

    Overlay.of(buildContext).insert(_tooltipEntry!);
  }

  @override
  void performLayout() {
    _cachedCell = null;
    _lastLocalPosition = null;

    final rowCount = _data.rowLabels.length;
    final colCount = _data.columnLabels.length;

    // Вычисляем отступы для подписей осей
    final metrics = _computeAxisMetrics(constraints, rowCount, colCount);

    _leftPadding = metrics.left;
    _topPadding = metrics.top;
    _bottomPadding = metrics.bottom;
    _rightPadding = metrics.right;


    // Доступное пространство для ячеек
    const outerPadding = 8.0;

    final availableWidth = (constraints.maxWidth - _leftPadding - _rightPadding - outerPadding)
      .clamp(0.0, double.infinity);
    final availableHeight = (constraints.maxHeight - _topPadding - _bottomPadding - outerPadding)
      .clamp(0.0, double.infinity);

    // Размеры ячеек (с ограничениями)
    _cellWidth = colCount > 0 ? (availableWidth / colCount).clamp(0.0, 200.0) : 28.0;
    _cellHeight = rowCount > 0 ? (availableHeight / rowCount).clamp(0.0, 200.0) : 28.0;

    final contentWidth = colCount * _cellWidth;
    final availableWidthForContent = constraints.maxWidth - _leftPadding - _rightPadding;

    if (availableWidthForContent > contentWidth) {
      final extraSpace = availableWidthForContent - contentWidth;
      // Центрируем область ячеек горизонтально
      _leftPadding += extraSpace / 2;
      _rightPadding += extraSpace / 2;
    }

    // Итоговый размер рендер-объекта
    final totalWidth = _leftPadding + colCount * _cellWidth + _rightPadding;
    final totalHeight = _topPadding + rowCount * _cellHeight + _bottomPadding;
    size = constraints.constrain(Size(totalWidth, totalHeight));
  }

  /// Обновляет мапперы цветов при смене палитры / colorMode / segments.
  ///
  /// Сохраняет текущий маппер как [_currentMapper] и создаёт новый как [_targetMapper].
  /// Это позволяет плавно анимировать переход между цветовыми схемами.
  ///
  /// Принимает:
  /// - [newConfig] - новая конфигурация тепловой карты
  /// - [newData] - новые данные (для определения min/max)
  void updateMappers(HeatmapConfig newConfig, HeatmapData newData) {
    _currentMapper = _targetMapper;
    _targetMapper = _createMapper(newConfig, newData);
  }

  /// Вычисляет отступы со всех четырёх сторон с учётом:
  /// - Наличия подписей осей (`showLabels`)
  /// - Длины и поворота подписей
  /// - Резерва места под легенду в правом верхнем углу
  AxisMetrics _computeAxisMetrics(
    BoxConstraints constraints,
    int rowCount,
    int colCount,
  ) {
    if (!_config.axis.showLabels) {
      // Когда подписи отключены — используем минимальные отступы,
      // но обязательно учитываем резерв под легенду сверху
      final topPadding = _config.legend.position == LegendPosition.topRight
          ? _config.legend.reserveTopSpace
          : 12.0;

      return AxisMetrics.noLabels(
        left: 16,           // небольшой отступ слева для красоты
        top: topPadding,
        right: 16,
        bottom: 0.0,
      );
    }

    // === showLabels == true ===
    // Выполняем итеративный расчёт, чтобы подписи точно помещались
    const outerPadding = 8.0;
    final bottomReserve = 16.0;

    double left = 48.0;
    double bottom = 24.0;

    // Итеративное уточнение отступов (до 4 проходов для сходимости)
    for (int iteration = 0; iteration < 4; iteration++) {
      final availableWidth = (constraints.maxWidth - left - outerPadding - _config.legend.reserveRightSpace)
          .clamp(0.0, double.infinity);

      final availableHeight = (constraints.maxHeight - left - bottomReserve - bottom)
          .clamp(0.0, double.infinity);   // здесь left используется как приближение top

      final cellWidth = colCount > 0 ? (availableWidth / colCount).clamp(28.0, 200.0) : 28.0;
      final cellHeight = rowCount > 0 ? (availableHeight / rowCount).clamp(28.0, 200.0) : 28.0;

      final textStyle = _axisTextStyle(cellWidth, cellHeight);

      // Максимальная ширина подписи строки
      final maxRowLabelWidth = _data.rowLabels
          .map((label) => _measureText(_shortenRowLabel(label), textStyle).width)
          .fold(0.0, math.max);

      // Максимальная высота подписи столбца с учётом поворота
      final maxColLabelHeight = _data.columnLabels
          .map((label) => _rotatedTextSize(
                _shortenColumnLabel(label, textStyle, cellWidth),
                textStyle,
                _config.axis.labelRotation,
              ).height)
          .fold(0.0, math.max);

      final newLeft = math.max(48.0, maxRowLabelWidth + 16.0);
      final newBottom = math.max(24.0, maxColLabelHeight + 12.0);

      if ((left - newLeft).abs() < 1.0 && (bottom - newBottom).abs() < 1.0) {
        left = newLeft;
        bottom = newBottom;
        break;
      }

      left = newLeft;
      bottom = newBottom;
    }

    double top = _config.legend.reserveTopSpace;

    if (_config.legend.position == LegendPosition.topRight) {
      top = math.max(top, _config.legend.reserveTopSpace);
    }

    return AxisMetrics(
      left: left,
      top: top,
      right: _config.legend.reserveRightSpace,
      bottom: bottom,
    );
  }

  // Вспомогательные методы для расчёта размеров текста (копия из старого виджета)
  TextStyle _axisTextStyle(double cellWidth, double cellHeight) {
    if (_config.axis.textStyle != null) return _config.axis.textStyle!;
    final baseSize = math.min(cellWidth, cellHeight) * 0.25;
    return TextStyle(
      fontSize: math.min(14.0, math.max(10.0, baseSize)),
      color: Colors.black87,
    );
  }

  String _shortenRowLabel(String label) {
    if (label.length <= 20) return label;
    return '${label.substring(0, 17)}…';
  }

  String _shortenColumnLabel(String label, TextStyle style, double cellWidth) {
    return _truncateText(label, style, cellWidth * 0.9);
  }

  String _truncateText(String text, TextStyle style, double maxWidth) {
    final fullWidth = _measureText(text, style).width;
    if (fullWidth <= maxWidth) return text;
    int low = 0;
    int high = text.length;
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

  Size _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
    )..layout();
    return tp.size;
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

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final holder = HeatmapPaintHolder(
      data: _data,
      targetData: _targetData,
      animationValue: _animationValue,
      config: _config,
      textScaler: _textScaler,
    );
    
    final painter = HeatmapPainter(
      holder: holder,
      cellWidth: _cellWidth,
      cellHeight: _cellHeight,
      leftPadding: _leftPadding,
      topPadding: _topPadding,
      bottomLabelOffset: _bottomLabelOffset,
      hoverRow: _hoverRow,
      hoverCol: _hoverCol,
      hoverRange: _externalHoverRange ?? _hoverRange,
    );
    painter.paint(canvas, size);
    canvas.restore();
  }

  // Обработка событий (наведение, касания) с учётом трансформации

  @override
  void detach() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    super.detach();
  }

  @override
  bool hitTestSelf(Offset position) => _config.touchData.enabled;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerExitEvent) {
      _hoverRow = null;
      _hoverCol = null;
      _hoverResponse = null;
      _resolvedCursor = SystemMouseCursors.basic;
      markNeedsPaint();
      _notifyTouchCallback(event, null);
      _updateTooltip(null);
      return;
    }

    if (!_config.touchData.enabled) return;
    
    final localPos = globalToLocal(event.position);
    final cell = _getCellAt(localPos);
    
    final oldRow = _hoverRow;
    final oldCol = _hoverCol;
    final oldResponse = _hoverResponse;
    
    _hoverRow = cell?.row;
    _hoverCol = cell?.col;
    
    if (_config.touchData.handleBuiltInTouches && cell != null) {
      _hoverResponse = HeatmapTouchResponse(
        touchLocation: event.position,
        touchChartCoordinate: localPos,
        cell: HeatmapCell(
          value: _data.values[cell.row][cell.col],
          rowLabel: _data.rowLabels[cell.row],
          colLabel: _data.columnLabels[cell.col],
          rowIndex: cell.row,
          colIndex: cell.col,
        ),
      );
    } else {
      _hoverResponse = null;
    }

    final newCursor = _config.touchData.mouseCursorResolver != null
        ? _config.touchData.mouseCursorResolver!(FlTouchEvent(event), _hoverResponse)
        : (_hoverResponse != null ? SystemMouseCursors.click : SystemMouseCursors.basic);

    if (_resolvedCursor != newCursor) {
      _resolvedCursor = newCursor;
      markNeedsPaint();
    }

    if (oldRow != _hoverRow || oldCol != _hoverCol || oldResponse != _hoverResponse) {
      markNeedsPaint();
      _notifyTouchCallback(event, cell);
      _updateTooltip(_hoverResponse);
    }
  }

  ({int row, int col})? _getCellAt(Offset localPosition) {
    // Если позиция не изменилась, возвращаем кэш
    if (_lastLocalPosition == localPosition && _cachedCell != null) {
      return _cachedCell;
    }
    
    _lastLocalPosition = localPosition;
    
    if (localPosition.dx < _leftPadding || localPosition.dy < _topPadding) {
      _cachedCell = null;
      return null;
    }
    final col = ((localPosition.dx - _leftPadding) / _cellWidth).floor();
    final row = ((localPosition.dy - _topPadding) / _cellHeight).floor();
    if (row >= 0 && row < _data.rowLabels.length && col >= 0 && col < _data.columnLabels.length) {
      _cachedCell = (row: row, col: col);
      return _cachedCell;
    }
    _cachedCell = null;
    return null;
  }

  void _notifyTouchCallback(PointerEvent event, ({int row, int col})? cell) {
    final callback = _config.touchData.touchCallback;
    if (callback == null) return;
    final response = HeatmapTouchResponse(
      touchLocation: event.position,
      touchChartCoordinate: globalToLocal(event.position),
      cell: cell != null
          ? HeatmapCell(
              value: _data.values[cell.row][cell.col],
              rowLabel: _data.rowLabels[cell.row],
              colLabel: _data.columnLabels[cell.col],
              rowIndex: cell.row,
              colIndex: cell.col,
            )
          : null,
    );
    callback(FlTouchEvent(event), response);
  }

  
}

/// {@template tooltip_position_delegate}
/// Делегат позиционирования тултипа для [CustomSingleChildLayout].
///
/// Автоматически выбирает оптимальное расположение тултипа относительно ячейки:
/// - Сверху (приоритет 1)
/// - Снизу (приоритет 2)
/// - Слева (приоритет 3)
/// - Справа (приоритет 4)
///
/// Исключает позиции, где тултип перекрывает саму ячейку.
/// При необходимости корректирует позицию, чтобы тултип не выходил за границы графика.
/// {@endtemplate}
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Глобальный центр целевой ячейки.
  final Offset targetGlobalCenter;
  
  /// Отступ тултипа от ячейки в пикселях.
  final double tooltipMargin;
  
  /// Флаг горизонтального вписывания в границы графика.
  final bool fitInsideHorizontally;
  
  /// Флаг вертикального вписывания в границы графика.
  final bool fitInsideVertically;
  
  /// Глобальный прямоугольник области графика.
  final Rect chartGlobalRect;
  
  /// Глобальный прямоугольник целевой ячейки.
  final Rect cellGlobalRect;

  _TooltipPositionDelegate({
    required this.targetGlobalCenter,
    required this.tooltipMargin,
    required this.fitInsideHorizontally,
    required this.fitInsideVertically,
    required this.chartGlobalRect,
    required this.cellGlobalRect,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Возвращаем свободные ограничения, чтобы тултип мог быть любого размера
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Вычисляем базовые позиции для четырёх сторон без корректировки
    final basePositions = <Offset>[
      Offset(targetGlobalCenter.dx - childSize.width / 2, 
             cellGlobalRect.top - childSize.height - tooltipMargin), // сверху
      Offset(targetGlobalCenter.dx - childSize.width / 2, 
             cellGlobalRect.bottom + tooltipMargin),                 // снизу
      Offset(cellGlobalRect.left - childSize.width - tooltipMargin, 
             targetGlobalCenter.dy - childSize.height / 2),          // слева
      Offset(cellGlobalRect.right + tooltipMargin, 
             targetGlobalCenter.dy - childSize.height / 2),          // справа
    ];

    // Для каждой позиции применяем корректировку, чтобы тултип не выходил за границы
    final adjustedPositions = basePositions.map((pos) => _adjustToFitChart(pos, childSize)).toList();

    // Ищем позицию, которая не перекрывает ячейку
    for (final pos in adjustedPositions) {
      final tooltipRect = Rect.fromLTWH(pos.dx, pos.dy, childSize.width, childSize.height);
      if (!tooltipRect.overlaps(cellGlobalRect)) {
        return pos;
      }
    }

    // Если все позиции перекрывают ячейку, выбираем наименее перекрывающую (сверху)
    return adjustedPositions[0];
  }

  Offset _adjustToFitChart(Offset pos, Size childSize) {
    var left = pos.dx;
    var top = pos.dy;
    
    if (fitInsideHorizontally) {
      if (left < chartGlobalRect.left) left = chartGlobalRect.left;
      if (left + childSize.width > chartGlobalRect.right) {
        left = chartGlobalRect.right - childSize.width;
      }
    }
    
    if (fitInsideVertically) {
      if (top < chartGlobalRect.top) top = chartGlobalRect.top;
      if (top + childSize.height > chartGlobalRect.bottom) {
        top = chartGlobalRect.bottom - childSize.height;
      }
    }
    
    return Offset(left, top);
  }


  @override
  bool shouldRelayout(covariant _TooltipPositionDelegate oldDelegate) {
    return targetGlobalCenter != oldDelegate.targetGlobalCenter ||
        tooltipMargin != oldDelegate.tooltipMargin ||
        fitInsideHorizontally != oldDelegate.fitInsideHorizontally ||
        fitInsideVertically != oldDelegate.fitInsideVertically ||
        chartGlobalRect != oldDelegate.chartGlobalRect ||
        cellGlobalRect != oldDelegate.cellGlobalRect;
  }
}