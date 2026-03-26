import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/model/hover_range.dart';
import '../color/heatmap_color_mapper.dart';

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
class HeatmapLegend extends StatelessWidget {
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

  /// {@macro heatmap_legend}
  const HeatmapLegend({
    super.key,
    required this.mapper,
    required this.min,
    required this.max,
    this.segments = 20,
    required this.onHover,
    required this.colorMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (colorMode == HeatmapColorMode.discrete) {
            return _buildDiscreteLegend(constraints.maxWidth);
          } else {
            return _buildGradientLegend(constraints.maxWidth);
          }
        },
      ),
    );
  }

  /// Строит легенду для дискретного режима.
  Widget _buildDiscreteLegend(double width) {
    final step = (max - min) / segments;
    final segmentWidth = width / segments;

    final children = <Widget>[];
    for (int i = 0; i < segments; i++) {
      final segmentMin = min + step * i;
      final segmentMax = min + step * (i + 1);
      final color = mapper.map(segmentMin + step / 2);
      children.add(
        _LegendSegment(
          width: segmentWidth,
          color: color,
          tooltip: '${segmentMin.toStringAsFixed(2)} – ${segmentMax.toStringAsFixed(2)}',
          onHover: () => onHover(HoverRange(min: segmentMin, max: segmentMax)),
          onExit: () => onHover(null),
        ),
      );
    }
    return Row(children: children);
  }

  /// Строит легенду для градиетного режима.
  Widget _buildGradientLegend(double width) {
    final colors = List.generate(segments + 1, (i) => mapper.map(min + i * (max - min) / segments));
    return _GradientLegend(
      width: width,
      colors: colors,
      min: min,
      max: max,
      onHover: onHover,
    );
  }
}

/// {@template legend_segment}
/// Сегмент дискретной легенды с интерактивным выделением.
/// 
/// Представляет один цветовой интервал с всплывающей подсказкой
/// и реакцией на наведение мыши.
class _LegendSegment extends StatelessWidget {
  final double width;
  final Color color;
  final String tooltip;
  final VoidCallback onHover;
  final VoidCallback onExit;

  const _LegendSegment({required this.width, required this.color, required this.tooltip, required this.onHover, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      onExit: (_) => onExit(),
      child: Container(
        width: width,
        height: 24,
        decoration: BoxDecoration(color: color, border: Border(right: BorderSide(color: Colors.grey.shade300))),
        child: Tooltip(message: tooltip, child: Container()),
      ),
    );
  }
}

/// {@template gradient_legend}
/// Легенда для градиентного режима с плавным переходом цветов
/// и отображением точного значения при наведении.
/// {@endtemplate}
class _GradientLegend extends StatefulWidget {
  final double width;
  final List<Color> colors;
  final double min;
  final double max;
  final ValueChanged<HoverRange?> onHover;

  const _GradientLegend({
    required this.width,
    required this.colors,
    required this.min,
    required this.max,
    required this.onHover,
  });

  @override
  State<_GradientLegend> createState() => _GradientLegendState();
}

class _GradientLegendState extends State<_GradientLegend> {
  OverlayEntry? _tooltipEntry;
  bool _isHovering = false;
  double _tooltipX = 0;
  double _tooltipY = 0;
  double? _currentValue;

  @override
  void initState() {
    super.initState();
    _createOverlayEntry();
  }

  @override
  void dispose() {
    _tooltipEntry?.remove();
    super.dispose();
  }

  void _createOverlayEntry() {
    _tooltipEntry = OverlayEntry(builder: (context) {
      return Positioned(
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
              _currentValue != null ? _currentValue!.toStringAsFixed(2) : '',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      );
    });
  }

  void _updateTooltip(Offset position) {
    final t = (position.dx / widget.width).clamp(0.0, 1.0);
    final value = widget.min + t * (widget.max - widget.min);
    _currentValue = value;
    widget.onHover(HoverRange(value: value));

    // Обновляем позицию тултипа
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final local = renderBox.globalToLocal(position);
      const tooltipWidth = 60.0;
      const tooltipHeight = 30.0;
      final left = local.dx - tooltipWidth / 2;
      final top = local.dy - tooltipHeight - 8;
      _tooltipX = left;
      _tooltipY = top;
      _tooltipEntry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (!_isHovering) {
          _isHovering = true;
          Overlay.of(context).insert(_tooltipEntry!);
        }
        _updateTooltip(event.position);
      },
      onExit: (_) {
        _isHovering = false;
        _tooltipEntry?.remove();
        widget.onHover(null);
      },
      child: Container(
        width: widget.width,
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}