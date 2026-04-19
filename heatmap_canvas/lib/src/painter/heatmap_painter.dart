import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import '../model/paint_holder.dart';
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
  final HeatmapPaintHolder holder;

  /// Ширина ячейки в пикселях
  final double cellWidth;

  /// Высота ячейки в пикселях
  final double cellHeight;

  /// Отступ слева до начала ячеек и подписей строк
  final double leftPadding;

  /// Отступ сверху до первой строки ячеек
  final double topPadding;

  /// Дополнительное пространство снизу для подписи столбцов
  final double bottomLabelOffset;

  /// Индекс строки под курсором (для подсветки)
  final int? hoverRow;

  /// Индекс колонки под курсором (для подсветки)
  final int? hoverCol;

  /// Информация о наведении на легенду
  final HoverRange? hoverRange;


  late HeatmapColorMapper _currentMapper;
  late HeatmapColorMapper _targetMapper;

  HeatmapPainter({
    required this.holder,
    required this.cellWidth,
    required this.cellHeight,
    required this.leftPadding,
    required this.topPadding,
    required this.bottomLabelOffset,
    this.hoverRow,
    this.hoverCol,
    this.hoverRange,
  }){
    _currentMapper = _createMapper(holder.data, holder.config);
    _targetMapper = _createMapper(holder.targetData, holder.config);
  }

  //  Кэширование

  ui.Picture? _gridPicture;
  ui.Picture? _rowLabelsPicture;
  ui.Picture? _colLabelsPicture;
  
  String? _cachedGridKey;
  String? _cachedRowLabelsKey;
  String? _cachedColLabelsKey;

  /// Кэш текстовых рисовальщиков для избежания повторного создания.
  /// Ключ: строка + стиль текста.
  final Map<String, TextPainter> _textCache = {};

  /// Переиспользуемый Paint для минимизации создания объектов.
  final Paint _paint = Paint();

  // Переиспользуемый Paint
  final Paint _highlightPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // Генерация ключей для кэша
  String _gridKey() => '${holder.data.rowLabels.length}_${holder.data.columnLabels.length}_'
      '${cellWidth}_${cellHeight}_${leftPadding}_${topPadding}_${bottomLabelOffset}_'
      '${holder.config.axis.showLabels}';

  String _rowLabelsKey() => '${holder.data.rowLabels.join()}_${holder.config.axis.textStyle}_'
      '${leftPadding}_$topPadding';

  String _colLabelsKey() => '${holder.data.columnLabels.join()}_${holder.config.axis.textStyle}_'
      '${holder.config.axis.labelRotation}_${cellWidth}_$bottomLabelOffset';

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
      textScaler: holder.textScaler,
    )..layout();
    _textCache[key] = tp;
    return tp;
  }

  // Цвета

  HeatmapColorMapper _createMapper(HeatmapData d, HeatmapConfig cfg) {
    final paletteColors = HeatmapPaletteFactory.baseColors(
      cfg.palette,
      customColors: cfg.customPaletteColors,
    );

    final min = d.min;
    final max = d.max;
    if (cfg.colorMode == HeatmapColorMode.discrete) {
      return DiscreteColorMapper(min: min, max: max, segments: cfg.segments, baseColors: paletteColors);
    } else {
      return GradientColorMapper(paletteType: cfg.palette, min: min, max: max);
    }
  }
  
  /// Возвращает анимированный цвет для заданного значения корреляции.
  ///
  /// Если есть предыдущий маппер и идет анимация, выполняет интерполяцию
  /// между старым и новым цветом.
  Color _getAnimatedColor(double value, double targetValue) {
    final color1 = _currentMapper.map(value);
    final color2 = _targetMapper.map(targetValue);
    return Color.lerp(color1, color2, holder.animationValue)!;
  }

  // Метод отрисовки сетки и фона
  ui.Picture _buildGridPicture(Size totalSize) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final rowCount = holder.data.rowLabels.length;
    final colCount = holder.data.columnLabels.length;
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Фон
    canvas.drawRect(Rect.fromLTWH(0, 0, totalSize.width, totalSize.height), Paint()..color = Colors.white);
    // Рамка вокруг ячеек
    canvas.drawRect(
      Rect.fromLTWH(leftPadding, topPadding, colCount * cellWidth, rowCount * cellHeight),
      Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    
    // Горизонтальные линии
    for (int i = 0; i <= rowCount; i++) {
      final y = topPadding + i * cellHeight;
      canvas.drawLine(Offset(leftPadding, y), Offset(totalSize.width, y), gridPaint);
    }
    // Вертикальные линии
    for (int i = 0; i <= colCount; i++) {
      final x = leftPadding + i * cellWidth;
      canvas.drawLine(Offset(x, topPadding), Offset(x, totalSize.height), gridPaint);
    }
    
    return recorder.endRecording();
  }

  // Метод отрисовки подписей строк
  ui.Picture _buildRowLabelsPicture(Size totalSize) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    if (!holder.config.axis.showLabels) return recorder.endRecording();
    
    final rowCount = holder.data.rowLabels.length;
    final stepRows = _computeLabelStep(cellHeight);

    final defaultStyle = TextStyle(
      fontSize: math.min(14.0, math.max(10.0, math.min(cellHeight, cellWidth) * 0.25)),
      color: Colors.black87,
    );

    final labelStyle = holder.config.axis.textStyle ?? defaultStyle;
    
    for (int i = 0; i < rowCount; i += stepRows) {
      String label = holder.data.rowLabels[i];

      if (holder.config.axis.labelFormatter != null) {
        label = holder.config.axis.labelFormatter!(label);
      }

      if (holder.config.checkToShowAxisLabel != null &&
          !holder.config.checkToShowAxisLabel!(label, Axis.vertical)) {
        continue;
      }
      
      final truncated = _truncateText(label, labelStyle, leftPadding - 12);
      final tp = _getTextPainter(truncated, labelStyle);
      tp.paint(canvas, Offset(
        leftPadding - tp.width - 8,
        topPadding + i * cellHeight + cellHeight / 2 - tp.height / 2,
      ));
    }
    return recorder.endRecording();
  }

  // Метод отрисовки подписей столбцов
  ui.Picture _buildColLabelsPicture(Size totalSize) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    if (!holder.config.axis.showLabels) return recorder.endRecording();
    
    final colCount = holder.data.columnLabels.length;
    final stepCols = _computeLabelStep(cellWidth);

    final defaultStyle = TextStyle(
      fontSize: math.min(14.0, math.max(10.0, math.min(cellHeight, cellWidth) * 0.25)),
      color: Colors.black87,
    );
    final labelStyle = holder.config.axis.textStyle ?? defaultStyle;
    final angle = holder.config.axis.labelRotation;
    final rowCount = holder.data.rowLabels.length;
    
    for (int i = 0; i < colCount; i += stepCols) {
      String label = holder.data.columnLabels[i];

      if (holder.config.axis.labelFormatter != null) {
        label = holder.config.axis.labelFormatter!(label);
      }
      if (holder.config.checkToShowAxisLabel != null &&
          !holder.config.checkToShowAxisLabel!(label, Axis.horizontal)) {
        continue;
      }
      
      final truncated = _truncateText(label, labelStyle, cellWidth * 0.9);
      final tp = _getTextPainter(truncated, labelStyle);
      canvas.save();
      canvas.translate(
        leftPadding + i * cellWidth + cellWidth / 2,
        topPadding + rowCount * cellHeight + 8,
      );
      canvas.rotate(angle);
      tp.paint(canvas, Offset(-tp.width / 2, 0));
      canvas.restore();
    }
    return recorder.endRecording();
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

  Size _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: holder.textScaler,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return tp.size;
  }


  /// Вычисляет шаг отображения подписей для перегруженных матриц.
  int _computeLabelStep(double cellDim) {
    if (cellDim > 39) return 1;
    if (cellDim > 25) return 2;
    return 4;
  }

  /// Вычисляет относительную яркость цвета (по стандарту WCAG)
  double _luminance(Color color) {
    final r = color.r / 255;
    final g = color.g / 255;
    final b = color.b / 255;

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

  TextPainter _layoutCellText(
    String text,
    double maxWidth,
    double maxHeight,
    TextStyle style,
  ) {
    double fontSize = style.fontSize ?? 12;
    fontSize = math.min(fontSize, math.min(maxWidth, maxHeight));
    TextPainter tp;

    while (fontSize >= 8) {
      tp = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: maxWidth);

      if (tp.height <= maxHeight && tp.width <= maxWidth) {
        return tp;
      }
      fontSize -= 1;
    }

    tp = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);
    return tp;
  }

  

  // Отрисовка
  @override
  void paint(Canvas canvas, Size size) {
    final data = holder.data;
    final targetData = holder.targetData;
    final config = holder.config;
    final rowCount = data.rowLabels.length;
    final colCount = data.columnLabels.length;
    if (rowCount == 0 || colCount == 0) return;

    final totalWidth = leftPadding + colCount * cellWidth;
    final totalHeight = topPadding + rowCount * cellHeight + bottomLabelOffset;
    final totalSize = Size(totalWidth, totalHeight);

    // Инвалидация и перестроение кэшей при необходимости
    final gridKey = _gridKey();
    if (_cachedGridKey != gridKey) {
      _gridPicture = _buildGridPicture(totalSize);
      _cachedGridKey = gridKey;
    }
    
    final rowKey = _rowLabelsKey();
    if (_cachedRowLabelsKey != rowKey) {
      _rowLabelsPicture = _buildRowLabelsPicture(totalSize);
      _cachedRowLabelsKey = rowKey;
    }
    
    final colKey = _colLabelsKey();
    if (_cachedColLabelsKey != colKey) {
      _colLabelsPicture = _buildColLabelsPicture(totalSize);
      _cachedColLabelsKey = colKey;
    }
    
    // Отрисовка статических слоёв
    canvas.drawPicture(_gridPicture!);
    canvas.drawPicture(_rowLabelsPicture!);
    canvas.drawPicture(_colLabelsPicture!);

    int startRow = 0, endRow = rowCount - 1;
    int startCol = 0, endCol = colCount - 1;
 

    // Отрисовка ячеек
    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        if (holder.config.triangleMode && col < row) continue;
        final value = data.values[row][col];
        if (value == 0) continue;
        final targetValue = targetData.values[row][col];
        final cell = HeatmapCell(
          value: value,
          rowLabel: data.rowLabels[row],
          colLabel: data.columnLabels[col],
          rowIndex: row,
          colIndex: col,
        );


        // Определяем цвет ячейки
        Color cellColor;
        final customColor = config.getCellColor?.call(cell);
        if (customColor != null) {
          cellColor = customColor;
        } else {
          cellColor = _getAnimatedColor(value, targetValue);
        }
        _paint.color = cellColor;


        final rect = Rect.fromLTWH(
          leftPadding + col * cellWidth,
          topPadding + row * cellHeight,
          cellWidth,
          cellHeight,
        );

        if (config.cellRenderer != null) {
          config.cellRenderer!(canvas, rect, cell);
        } else {
          canvas.drawRect(rect, _paint);

          // Отрисовка обводки
          final border = config.getCellBorder?.call(cell);
          if (border != null) {
            final borderPaint = Paint()
              ..color = border.color
              ..strokeWidth = border.strokeWidth
              ..style = PaintingStyle.stroke;
            canvas.drawRect(rect, borderPaint);
          }

          // Значения в ячейках
          if (config.showValues) {
            String text;
            final customLabel = config.getCellLabel?.call(cell);
            if (customLabel != null) {
              text = customLabel;
            } else {
              text = config.cellValueFormatter?.call(value) ?? formatHeatmapNumber(value);
            }
            
            final textColor = _contrastColor(cellColor);
            final tp = _layoutCellText(
              text,
              cellWidth - 8,
              cellHeight - 6,
              TextStyle(
                fontSize: math.min(cellWidth, cellHeight) * 0.35,
                color: textColor,
                fontWeight: FontWeight.w600,
                shadows: textColor == Colors.white
                    ? [const Shadow(blurRadius: 1.5, color: Colors.black54)]
                    : null,
              ),
            );
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
              leftPadding + col * cellWidth,
              topPadding + row * cellHeight,
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
      final rect = Rect.fromLTWH(
        leftPadding + hoverCol! * cellWidth,
        topPadding + hoverRow! * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect, _highlightPaint);
    }
  }

  // Определение необходимости перерисовки
  @override
  bool shouldRepaint(covariant HeatmapPainter old) {
    return old.holder != holder ||
        old.cellWidth != cellWidth ||
        old.cellHeight != cellHeight ||
        old.leftPadding != leftPadding ||
        old.topPadding != topPadding ||
        old.bottomLabelOffset != bottomLabelOffset ||
        old.hoverRow != hoverRow ||
        old.hoverCol != hoverCol ||
        old.hoverRange != hoverRange;
  }
}