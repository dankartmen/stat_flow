import 'package:flutter/material.dart';

import '../model/correlation_matrix.dart';
import '../color/heatmap_color_mapper.dart';

/// {@template heatmap_painter}
/// Кастомный рисовальщик для отрисовки тепловой карты корреляции.
/// {@endtemplate}
class HeatmapPainter extends CustomPainter {
  /// Матрица корреляции для визуализации
  final CorrelationMatrix matrix;
  
  /// Текущий маппер цветов
  final HeatmapColorMapper colorMapper;
  
  /// Предыдущий маппер цветов (для анимации перехода)
  final HeatmapColorMapper previousMapper;
  
  /// Значение анимации перехода между мапперами (0..1)
  final double animationValue;
  
  /// Размер ячейки в пикселях
  final double cellSize;
  
  /// Отображать ли значения внутри ячеек
  final bool showValues;
  
  /// Индекс строки под курсором (для подсветки)
  final int? hoverRow;
  
  /// Индекс колонки под курсором (для подсветки)
  final int? hoverCol;
  
  /// Режим отображения только верхнего треугольника
  final bool triangleMode;
  
  /// Кэш текстовых рисовальщиков для оптимизации производительности
  static final Map<String, TextPainter> _textCache = {};

  /// {@macro heatmap_painter}
  HeatmapPainter({
    this.hoverRow, 
    this.hoverCol, 
    this.triangleMode = false,
    required this.matrix,
    required this.colorMapper,
    required this.previousMapper,
    required this.animationValue,
    required this.cellSize,
    required this.showValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final axisOffset = cellSize; // область под оси
    
    // Рисуем ячейки матрицы
    for (int row = 0; row < matrix.size; row++) {
      for (int col = 0; col < matrix.size; col++) {

        // В режиме треугольника пропускаем ячейки ниже диагонали
        if (triangleMode == true && col < row) continue;
        
        final value = matrix.getByIndex(row, col);

        final x = axisOffset + col * cellSize;
        final y = axisOffset + row * cellSize;

        final oldColor = previousMapper.map(value);
        final newColor = colorMapper.map(value);

        final animatedColor =
            Color.lerp(oldColor, newColor, animationValue)!;

        // Рисуем ячейку
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          paint..color = animatedColor,
        );

        // Отображаем числовое значение, если включено и достаточно места
        if (showValues && cellSize > 30) {
          _drawCenteredText(
            canvas,
            value.toStringAsFixed(2),
            x,
            y,
            value,
          );
        }
      }
    }

    // Подсветка ячейки под курсором
    if (hoverRow != null && hoverCol != null) {
      final axisOffset = cellSize;

      final x = axisOffset + hoverCol! * cellSize;
      final y = axisOffset + hoverRow! * cellSize;

      final highlightPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        highlightPaint,
      );
    }

    // Рисуем оси с названиями полей
    _drawAxis(canvas, axisOffset);

    // Рисуем сетку
    _drawGrid(canvas, axisOffset);
  }

  /// Рисование осей с названиями полей
  void _drawAxis(Canvas canvas, double axisOffset) {
    final fields = matrix.fieldNames;

    for (int i = 0; i < matrix.size; i++) {
      final label = fields[i];

      // Верхняя ось (названия колонок)
      _drawCenteredText(
        canvas,
        label,
        axisOffset + i * cellSize,
        0,
        0,
        isAxis: true,
      );

      // Левая ось (названия строк)
      _drawCenteredText(
        canvas,
        label,
        0,
        axisOffset + i * cellSize,
        0,
        isAxis: true,
      );
    }
  }

  /// Рисование центрированного текста в ячейке
  void _drawCenteredText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double value, {
    bool isAxis = false,
  }) {
    final key = "$text-$cellSize-$isAxis";

    TextPainter textPainter;

    // Используем кэш для избежания повторного создания
    if (_textCache.containsKey(key)) {
      textPainter = _textCache[key]!;
    } else {
      textPainter = TextPainter(
        text: TextSpan(
          // Обрезаем длинные названия для осей
          text: text.length > 10 ? "${text.substring(0, 9)}…" : text,
          style: TextStyle(
            color: isAxis
                ? Colors.black
                : (value.abs() > 0.4 ? Colors.white : Colors.black),
            fontSize: isAxis
                ? cellSize * 0.25
                : cellSize * 0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      _textCache[key] = textPainter;
    }

    final offset = Offset(
      x + (cellSize - textPainter.width) / 2,
      y + (cellSize - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);
  }

  /// Рисование сетки вокруг ячеек
  void _drawGrid(Canvas canvas, double axisOffset) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final total = cellSize * (matrix.size + 1);

    for (int i = 0; i <= matrix.size; i++) {
      final pos = axisOffset + i * cellSize;

      // Горизонтальные линии
      canvas.drawLine(
        Offset(axisOffset, pos),
        Offset(total, pos),
        gridPaint,
      );

      // Вертикальные линии
      canvas.drawLine(
        Offset(pos, axisOffset),
        Offset(pos, total),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter old) {
    return old.matrix != matrix ||
        old.cellSize != cellSize ||
        old.showValues != showValues ||
        old.colorMapper != colorMapper ||
        old.previousMapper != previousMapper ||
        old.animationValue != animationValue ||
        old.hoverRow != hoverRow ||
        old.hoverCol != hoverCol ||
        old.triangleMode != triangleMode ||
        old.matrix != matrix;
  }
}