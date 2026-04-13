import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../color/heatmap_color_mapper.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import '../utils/number_formatter.dart';

/// Кастомный рисовальщик для отрисовки тепловой карты.
///
/// Отвечает за:
/// - Отрисовку ячеек с анимированным переходом цветов
/// - Отображение сетки и подписей осей
/// - Рендеринг значений внутри ячеек
/// - Подсветку ячейки при наведении и показ тултипа
/// - Кэширование статического слоя (сетка и подписи) для оптимизации
class HeatmapPainter extends CustomPainter {
  /// Данные для отображения
  final HeatmapData data;

  /// Текущий маппер цветов
  final HeatmapColorMapper colorMapper;

  /// Предыдущий маппер (для анимации перехода)
  final HeatmapColorMapper? previousMapper;

  /// Значение анимации перехода (0..1)
  final double animationValue;

  /// Ширина ячейки в пикселях
  final double cellWidth;

  /// Высота ячейки в пикселях
  final double cellHeight;

  /// Конфигурация отображения
  final HeatmapConfig config;

  /// Смещение от края для подписей осей (вычисляется снаружи)
  final double axisOffset;

  /// Индекс строки под курсором (для подсветки)
  final int? hoverRow;

  /// Индекс колонки под курсором (для подсветки)
  final int? hoverCol;

  /// Информация о наведении на легенду
  final HoverRange? hoverRange;

  /// Видимая область для оптимизации отрисовки больших матриц
  final Rect? visibleRect;

  HeatmapPainter({
    required this.data,
    required this.colorMapper,
    required this.previousMapper,
    required this.animationValue,
    required this.cellWidth,
    required this.cellHeight,
    required this.config,
    required this.axisOffset,
    this.hoverRow,
    this.hoverCol,
    this.hoverRange,
    this.visibleRect,
  });

  //  Кэширование 
  
  /// Кэш статического слоя (сетка + подписи осей).
  /// Перестраивается только при изменении матрицы или размера ячейки.
  ui.Picture? _staticLayer;

  /// Ключ для идентификации текущего статического слоя.
  String? _cachedStaticLayerKey;

  /// Кэш текстовых рисовальщиков для избежания повторного создания.
  /// Ключ: строка + стиль текста.
  final Map<String, TextPainter> _textCache = {};

  /// Переиспользуемый Paint для минимизации создания объектов.
  final Paint _paint = Paint();

  // Кэш цветов для текущего кадра анимации
  List<List<Color>>? _colorCache;
  double _cachedAnimationValue = -1;

  // Переиспользуемый Paint
  final Paint _highlightPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  /// Генерирует ключ для кэша статического слоя.
  String _staticLayerKey() =>
      '${data.rowLabels.length}_${data.columnLabels.length}_'
      '${cellWidth}_${cellHeight}_${axisOffset}_'
      '${config.showAxisLabels}_${config.axisTextStyle}_${config.axisLabelRotation}';

  /// Получает или создает TextPainter для заданного текста и стиля.
  ///
  /// Использует кэширование для повышения производительности при частых
  /// перерисовках (например, во время анимации).
  TextPainter _getTextPainter(String text, TextStyle style) {
    final key = "$text-${style.fontSize}-${style.color}-${style.fontWeight}";
    if (_textCache.containsKey(key)) return _textCache[key]!;

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    _textCache[key] = tp;
    return tp;
  }

  // Цвета 

  /// Возвращает анимированный цвет для заданного значения корреляции.
  ///
  /// Если есть предыдущий маппер и идет анимация, выполняет интерполяцию
  /// между старым и новым цветом.
  Color _getAnimatedColor(double value) {
    if (previousMapper == null) return colorMapper.map(value);
    final oldColor = previousMapper!.map(value);
    final newColor = colorMapper.map(value);
    return Color.lerp(oldColor, newColor, animationValue)!;
  }

  /// Получает цвет для ячейки с кэшированием. Если кэш для текущего значения анимации
  /// существует, возвращает его. Иначе пересчитывает цвета для всех ячеек и сохраняет в кэше.
  Color _getCachedColor(int row, int col) {
    if (_colorCache != null && _cachedAnimationValue == animationValue) {
      return _colorCache![row][col];
    }
    _cachedAnimationValue = animationValue;
    _colorCache = List.generate(data.rowLabels.length, (r) {
      return List.generate(data.columnLabels.length, (c) {
        return _getAnimatedColor(data.values[r][c]);
      });
    });
    return _colorCache![row][col];
  }

  //  Статический слой (сетка + оси)
  ui.Picture _buildStaticLayer() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final rowCount = data.rowLabels.length;
    final colCount = data.columnLabels.length;
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final totalWidth = colCount * cellWidth + axisOffset;
    final totalHeight = rowCount * cellHeight + axisOffset;

    // Горизонтальные линии
    // for (int i = 0; i <= rowCount; i++) {
    //   final y = axisOffset + i * cellHeight;
    //   canvas.drawLine(Offset(axisOffset, y), Offset(totalWidth, y), gridPaint);
    // }
    // // Вертикальные линии
    // for (int i = 0; i <= colCount; i++) {
    //   final x = axisOffset + i * cellWidth;
    //   canvas.drawLine(Offset(x, axisOffset), Offset(x, totalHeight), gridPaint);
    // }

    if (config.showAxisLabels) {
      final angle = _computeLabelAngle();
      final stepRows = _computeLabelStep(cellHeight);
      final stepCols = _computeLabelStep(cellWidth);

      final labelStyle = config.axisTextStyle ??
          TextStyle(
            fontSize: math.min(cellHeight, cellWidth) * 0.25,
            color: Colors.black87,
          );

      // Подписи строк (слева)
      for (int i = 0; i < rowCount; i += stepRows) {
        final label = _smartLabel(data.rowLabels[i]);
        final tp = _getTextPainter(label, labelStyle);
        tp.paint(
          canvas,
          Offset(
            axisOffset - tp.width - 4,
            axisOffset + i * cellHeight + cellHeight / 2 - tp.height / 2,
          ),
        );
      }

      // Подписи столбцов (снизу)
      for (int i = 0; i < colCount; i += stepCols) {
        final label = _smartLabel(data.columnLabels[i]);
        final tp = _getTextPainter(label, labelStyle);
        canvas.save();
        canvas.translate(
          axisOffset + i * cellWidth + cellWidth / 2,
          totalHeight - axisOffset + 6,
        );
        canvas.rotate(angle);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height));
        canvas.restore();
      }
    }

    return recorder.endRecording();
  }

  // Умное сокращение длинных названий
  String _smartLabel(String text, {int max = 16}) {
    if (text.length <= max) return text;
    final parts = text.split('_');
    if (parts.length > 1) {
      return parts.map((e) => e.characters.first).join();
    }
    return '${text.substring(0, max)}…';
  }

  double _computeLabelAngle() {
    // Используем угол из конфига, если задан явно
    return config.axisLabelRotation;
  }

  /// Вычисляет шаг отображения подписей для перегруженных матриц.
  int _computeLabelStep(double cellDim) {
    if (cellDim > 39) return 1;
    if (cellDim > 25) return 2;
    return 4;
  }

  /// Вычисляет относительную яркость цвета (по стандарту WCAG)
  double _luminance(Color color) {
    final r = color.red / 255;
    final g = color.green / 255;
    final b = color.blue / 255;
    
    double linearize(double channel) {
      return channel <= 0.03928 
          ? channel / 12.92 
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
    
    final R = linearize(r);
    final G = linearize(g);
    final B = linearize(b);
    
    return 0.2126 * R + 0.7152 * G + 0.0722 * B;
  }

  /// Возвращает контрастный цвет текста (чёрный или белый) для заданного фона.
  Color _contrastColor(Color background) {
    return _luminance(background) > 0.5 ? Colors.black87 : Colors.white;
  }

  // Отрисовка
  @override
  void paint(Canvas canvas, Size size) {
    final rowCount = data.rowLabels.length;
    final colCount = data.columnLabels.length;
    if (rowCount == 0 || colCount == 0) return;

    final isSquare = rowCount == colCount;
    final effectiveTriangleMode = config.triangleMode && isSquare;

    // Отрисовка статического слоя
    final key = _staticLayerKey();
    if (_cachedStaticLayerKey != key) {
      _staticLayer = null;
      _cachedStaticLayerKey = key;
    }
    _staticLayer ??= _buildStaticLayer();
    canvas.drawPicture(_staticLayer!);

    // Видимый диапазон
    int startRow = 0, endRow = rowCount - 1;
    int startCol = 0, endCol = colCount - 1;
    if (visibleRect != null) {
      startRow = visibleRect!.top.floor().clamp(0, rowCount - 1);
      endRow = visibleRect!.bottom.floor().clamp(0, rowCount - 1);
      startCol = visibleRect!.left.floor().clamp(0, colCount - 1);
      endCol = visibleRect!.right.floor().clamp(0, colCount - 1);
    }

    // Отрисовка ячеек
    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        if (effectiveTriangleMode && col < row) continue;
        if (data.values[row][col] == 0) continue;
        _paint.color = _getCachedColor(row, col);
        final rect = Rect.fromLTWH(
          axisOffset + col * cellWidth,
          axisOffset + row * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawRect(rect, _paint);

        // Значения в ячейках
        if (config.showValues) {
          final value = data.values[row][col];
          final formatted = config.cellValueFormatter?.call(value) ??
              formatHeatmapNumber(value);

          final backgroundColor = _getCachedColor(row, col);
          final textColor = _contrastColor(backgroundColor);

          final textStyle = TextStyle(
            fontSize: math.min(cellWidth, cellHeight) * 0.5,
            color: textColor,
            fontWeight: FontWeight.w500,
            shadows: textColor == Colors.white
                ? [const Shadow(blurRadius: 1.5, color: Colors.black54)]
                : null,
          );
          final tp = _getTextPainter(formatted, textStyle);
          tp.paint(
            canvas,
            Offset(
              rect.center.dx - tp.width / 2,
              rect.center.dy - tp.height / 2,
            ),
          );
        }
      }
    }

    // Подсветка от легенды
    if (hoverRange != null) {
      final highlightPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final dataRange = data.max - data.min;
      final tolerance = dataRange * 0.001;

      for (int row = startRow; row <= endRow; row++) {
        for (int col = startCol; col <= endCol; col++) {
          final value = data.values[row][col];
          bool match = false;
          if (hoverRange!.value != null) {
            // градиентный режим – выделяем ячейки, значение которых близко к hoveredValue
            match = (value - hoverRange!.value!).abs() < tolerance;
          } else if (hoverRange!.min != null && hoverRange!.max != null) {
            // дискретный режим
            match = value >= hoverRange!.min! && value <= hoverRange!.max!;
          }
          if (match) {
            final rect = Rect.fromLTWH(
              axisOffset + col * cellWidth,
              axisOffset + row * cellHeight,
              cellWidth,
              cellHeight,
            );
            canvas.drawRect(rect, highlightPaint);
          }
        }
      }
    }

    // Подсветка под курсором и тултип
    if (hoverRow != null &&
        hoverCol != null &&
        hoverRow! >= startRow &&
        hoverRow! <= endRow &&
        hoverCol! >= startCol &&
        hoverCol! <= endCol) {
      final left = axisOffset + hoverCol! * cellWidth;
      final top = axisOffset + hoverRow! * cellHeight;
      canvas.drawRect(
        Rect.fromLTWH(left, top, cellWidth, cellHeight),
        _highlightPaint,
      );
    }
  }

  // Определение необходимости перерисовки
  @override
  bool shouldRepaint(covariant HeatmapPainter old) {
    final repaint = old.data != data ||
        old.colorMapper != colorMapper ||
        old.previousMapper != previousMapper ||
        old.animationValue != animationValue ||
        old.cellWidth != cellWidth ||
        old.cellHeight != cellHeight ||
        old.config != config ||
        old.axisOffset != axisOffset ||
        old.hoverRow != hoverRow ||
        old.hoverCol != hoverCol ||
        old.hoverRange != hoverRange ||
        old.visibleRect != visibleRect;

    if (repaint) {
      _textCache.clear();
      _colorCache = null;
    }
    return repaint;
  }
}