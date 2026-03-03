import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stat_flow/features/charts/heatmap/correlation_matrix.dart';

import 'correlation_color_scale.dart';
import 'heatmap_grid.dart';

/// {@template correlation_heatmap}
/// Виджет для отображения тепловой карты корреляции.
/// Поддерживает масштабирование и панорамирование.
/// {@endtemplate}
class CorrelationHeatmap extends StatefulWidget {
  /// Матрица корреляции
  final CorrelationMatrix correlationMatrix;

  /// {@macro correlation_heatmap}
  const CorrelationHeatmap({
    required this.correlationMatrix,
    super.key,
  });

  @override
  State<CorrelationHeatmap> createState() => _CorrelationHeatmapState();
}

class _CorrelationHeatmapState extends State<CorrelationHeatmap> {
  /// Контроллер трансформаций (масштаб + панорамирование)
  final TransformationController _controller = TransformationController();

  /// Минимальный масштаб
  static const double _minScale = 0.35;

  /// Максимальный масштаб
  static const double _maxScale = 3.0;

  /// Шаг масштабирования колесиком
  static const double _wheelScaleFactor = 1.1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Обработка колесика мыши + Ctrl
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (!isCtrlPressed) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final focalPoint = renderBox.globalToLocal(event.position);

    final scale = event.scrollDelta.dy < 0
        ? _wheelScaleFactor
        : 1 / _wheelScaleFactor;

    final matrix = _controller.value.clone();

    /// Смещаем фокус в начало координат,
    /// масштабируем,
    /// возвращаем обратно
    matrix
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scale)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    _controller.value = matrix;
  }

  /// Сброс масштаба и позиции
  void _resetTransform() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.correlationMatrix.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: Listener(
                onPointerSignal: _handlePointerSignal,
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: HeatmapGrid(
                    matrix: widget.correlationMatrix,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegendAndControls(),
          ],
        ),
      ),
    );
  }

  /// Заголовок виджета
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Тепловая карта корреляции',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Используйте Ctrl + колесико мыши для масштабирования',
          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  /// Легенда и кнопки управления
  Widget _buildLegendAndControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLegend(),
        IconButton(
          tooltip: 'Сбросить масштаб',
          icon: const Icon(Icons.restore),
          onPressed: _resetTransform,
        ),
      ],
    );
  }

  /// Легенда корреляций
  Widget _buildLegend() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: correlationColorScale.map((range) {
        return _LegendItem(range.label, range.color);
      }).toList(),
    );
  }

  /// Состояние без данных
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Нет данных для построения тепловой карты',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}





/// Элемент легенды
class _LegendItem extends StatelessWidget {
  final String text;
  final Color color;

  const _LegendItem(this.text, this.color);

  @override 
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

