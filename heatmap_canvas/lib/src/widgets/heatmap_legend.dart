import 'package:flutter/material.dart';
import '../model/legend_tooltip_info.dart';
import '../model/hover_range.dart';
import '../color/heatmap_color_mapper.dart';
import '../utils/number_formatter.dart';

/// {@template heatmap_legend}
/// Компактная градиентная легенда для тепловой карты.
/// 
/// Отображает цветовую шкалу с подписями минимального, среднего
/// и максимального значения. Автоматически генерирует градиент
/// на основе текущего [HeatmapColorMapper].
/// 
/// Особенности:
/// - Плавный градиент от минимального к максимальному значению
/// - Компактный дизайн с рамкой
/// - Автоматическое форматирование подписей
/// - Интерактивная подсветка ячеек при наведении
/// {@endtemplate}
class HeatmapLegend extends StatefulWidget {
  /// Маппер цветов для генерации градиента
  final HeatmapColorMapper mapper;

  /// Режим раскраски (дискретный/градиентный)
  final HeatmapColorMode colorMode;

  /// Минимальное значение шкалы
  final double min;

  /// Максимальное значение шкалы
  final double max;

  /// Количество сегментов для построения градиента
  final int segments;

  /// Колбек для передачи информации о наведении на легенду
  final ValueChanged<HoverRange?> onHover;

  final Widget Function(BuildContext context, LegendTooltipInfo? value)? legendTooltipBuilder;
  
  /// {@macro heatmap_legend}
  const HeatmapLegend({
    super.key,
    this.segments = 20,
    this.legendTooltipBuilder,
    required this.mapper,
    required this.min,
    required this.max,    
    required this.onHover,
    required this.colorMode,
  });

  @override
  State<HeatmapLegend> createState() => _HeatmapLegendState();
}

class _HeatmapLegendState extends State<HeatmapLegend> {
  /// Данные для отображения в легенде
  OverlayEntry? _tooltipEntry;

  /// Флаг, указывающий, находится ли курсор на легендой
  bool _isHovering = false;
  
  /// Позиция тултипа
  double _tooltipX = 0;
  double _tooltipY = 0;

  /// Текущее значение, отображаемое в тултипе
  double? _currentValue;

  /// Текущая информация, отображаемая в тултипе
  LegendTooltipInfo? _currentInfo;

  /// Позиция маркера для градиентного режима
  double _markerX = 0;

  /// Флаг для отображения маркера в градиентном режиме
  bool _showMarker = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tooltipEntry?.remove();
    super.dispose();
  }


  /// Создаёт оверлей для отображения тултипа при наведении на легенду
  /// Тултип показывает диапазон значений для дискретного режима или точное значение для градиентного режима
  /// Позиция тултипа рассчитывается так, чтобы он не выходил за пределы экрана
  /// Тултип автоматически обновляется при перемещении мыши по легенде
  void _createTooltipEntry() {
    if (widget.legendTooltipBuilder != null) {
      _tooltipEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: _tooltipX,
          top: _tooltipY,
          child: Material(
            color: Colors.transparent,
            child: widget.legendTooltipBuilder!(context, _currentInfo),
          ),
        ),
      );
    } else {
      // Стандартный тултип
      _tooltipEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: _tooltipX,
          top: _tooltipY,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _tooltipText(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Генерирует текст для тултипа в зависимости от текущего значения и режима раскраски
  String _tooltipText() {
    if (_currentValue == null) return '';
    if (widget.colorMode == HeatmapColorMode.discrete) {
      final step = (widget.max - widget.min) / widget.segments;
      final segmentIndex = ((_currentValue! - widget.min) / step).floor();
      final segmentMin = widget.min + step * segmentIndex;
      final segmentMax = widget.min + step * (segmentIndex + 1);
      return '[${formatHeatmapNumber(segmentMin)} , ${formatHeatmapNumber(segmentMax)}]';
    } else {
      return formatHeatmapNumber(_currentValue!);
    }
  }

  /// Обновляет позицию и содержимое тултипа при перемещении мыши по легенде
  void _updateTooltip(Offset position, RenderBox renderBox) {
    // Преобразуем глобальную позицию мыши в локальную относительно легенды
    final local = renderBox.globalToLocal(position);
    final width = renderBox.size.width;
    /// Вычисляем значение на шкале, соответствующее текущей позиции мыши
    final t = (local.dx / width).clamp(0.0, 1.0);
    /// Интерполируем значение между min и max на основе позиции мыши
    final value = widget.min + t * (widget.max - widget.min);
    _currentValue = value;

    double? segmentMin, segmentMax;
    int? segIndex;

    if (widget.colorMode == HeatmapColorMode.gradient) {
      _markerX = local.dx;
      _showMarker = true;
    }

    // Вызываем колбек с информацией о наведении в зависимости от режима раскраски
    if (widget.colorMode == HeatmapColorMode.discrete) {
      final step = (widget.max - widget.min) / widget.segments;
      segIndex = ((value - widget.min) / step).floor().clamp(0, widget.segments - 1);
      segmentMin = widget.min + step * segIndex;
      segmentMax = widget.min + step * (segIndex + 1);
      _markerX = local.dx;
      widget.onHover(HoverRange(min: segmentMin, max: segmentMax));
    } else {
      widget.onHover(HoverRange(value: value));
    }

    _currentInfo = LegendTooltipInfo(
      value: value,
      segmentMin: segmentMin,
      segmentMax: segmentMax,
      segmentIndex: segIndex,
      colorMode: widget.colorMode,
    );
    
    // Рассчитываем позицию тултипа так, чтобы он не выходил за пределы экрана
    const barHeight = 16.0;
    const spacing = 0.0;
    const tooltipWidth = 80.0;
    const tooltipHeight = 28.0;

    final legendGlobalTop = renderBox.localToGlobal(Offset.zero);
    final barBottom = legendGlobalTop.dy + barHeight;

    final globalMarkerCenter = renderBox.localToGlobal(Offset(_markerX, 0));

    double tooltipLeft = globalMarkerCenter.dx - tooltipWidth / 2;
    double tooltipTop = barBottom + spacing;
    final screenSize = MediaQuery.of(context).size;
    tooltipLeft = tooltipLeft.clamp(0.0, screenSize.width - tooltipWidth);
    tooltipTop = tooltipTop.clamp(0.0, screenSize.height - tooltipHeight);
    _tooltipX = tooltipLeft;
    _tooltipY = tooltipTop;
    _tooltipEntry?.markNeedsBuild();
    setState(() {
    });
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 40.0;
        final colors = List.generate(
          widget.segments + 1,
          (i) => widget.mapper.map(widget.min + i * (widget.max - widget.min) / widget.segments),
        );

        return SizedBox(
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                onHover: (event) {
                  if (!_isHovering) {
                    _isHovering = true;
                    _createTooltipEntry();
                    Overlay.of(context).insert(_tooltipEntry!);
                  }
                  final renderBox = context.findRenderObject() as RenderBox;
                  _updateTooltip(event.position, renderBox);
                },
                onExit: (_) {
                  _isHovering = false;
                  _tooltipEntry?.remove();
                  _tooltipEntry = null;
                  _showMarker = false;
                  widget.onHover(null);
                  setState(() {
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: width,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    if (_showMarker)
                      Positioned(
                        left: _markerX - 6, // центрируем маркер
                        top: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70, width: 26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatHeatmapNumber(widget.min), style: const TextStyle(fontSize: 11)),
                  Text(formatHeatmapNumber(widget.max), style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}