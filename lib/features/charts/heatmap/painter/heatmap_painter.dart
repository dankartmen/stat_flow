import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../model/correlation_matrix.dart';
import '../color/heatmap_color_mapper.dart';

/// {@template heatmap_painter}
/// Кастомный рисовальщик для отрисовки тепловой карты корреляции.
/// 
/// Отвечает за:
/// - Отрисовку ячеек тепловой карты с анимированным переходом цветов
/// - Отображение сетки и подписей осей
/// - Рендеринг значений внутри ячеек
/// - Подсветку ячейки при наведении и показ тултипа
/// - Кэширование статического слоя (сетка и подписи) для оптимизации
/// {@endtemplate}
class HeatmapPainter extends CustomPainter {
  /// Матрица корреляции для визуализации
  final CorrelationMatrix matrix;

  /// Текущий маппер цветов
  final HeatmapColorMapper colorMapper;

  /// Предыдущий маппер цветов (для анимации перехода)
  final HeatmapColorMapper? previousMapper;

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
  /// (скрывает нижнюю половину матрицы)
  final bool triangleMode;

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

 

  /// Кэш статического слоя (сетка + подписи осей).
  /// Перестраивается только при изменении матрицы или размера ячейки.
  ui.Picture? _staticLayer;

  /// Кэш текстовых рисовальщиков для избежания повторного создания.
  /// Ключ: строка + стиль текста.
  final Map<String, TextPainter> _textCache = {};

  /// Переиспользуемый Paint для минимизации создания объектов.
  final Paint _paint = Paint();


  /// Получает или создает TextPainter для заданного текста и стиля.
  ///
  /// Использует кэширование для повышения производительности при частых
  /// перерисовках (например, во время анимации).
  TextPainter _getTextPainter(String text, TextStyle style) {
    final key = "$text-${style.fontSize}-${style.color}-${style.fontWeight}";

    if (_textCache.containsKey(key)) {
      return _textCache[key]!;
    }

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    _textCache[key] = tp;
    return tp;
  }



  /// Возвращает анимированный цвет для заданного значения корреляции.
  ///
  /// Если есть предыдущий маппер и идет анимация, выполняет интерполяцию
  /// между старым и новым цветом.
  Color _getAnimatedColor(double value) {
    if (previousMapper == null) {
      return colorMapper.map(value);
    }

    final oldColor = previousMapper!.map(value);
    final newColor = colorMapper.map(value);

    return Color.lerp(oldColor, newColor, animationValue)!;
  }



  /// Создает статический слой с сеткой и подписями осей.
  ///
  /// Этот слой не изменяется при анимации и перерисовывается только
  /// при изменении матрицы или размера ячейки.
  ui.Picture _buildStaticLayer() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final n = matrix.size;
    final axisOffset = cellSize; // Отступ от края для подписей

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final total = cellSize * (n + 1);

    // Рисуем горизонтальные и вертикальные линии сетки
    for (int i = 0; i <= n; i++) {
      final pos = axisOffset + i * cellSize;

      // Горизонтальная линия
      canvas.drawLine(
        Offset(axisOffset, pos),
        Offset(total, pos),
        gridPaint,
      );

      // Вертикальная линия
      canvas.drawLine(
        Offset(pos, axisOffset),
        Offset(pos, total),
        gridPaint,
      );
    }

    // Отрисовка подписей осей
    final angle = _computeLabelAngle();
    final step = _computeLabelStep();

    for (int i = 0; i < n; i += step) {
      final label = _smartLabel(matrix.fieldNames[i]);

      final style = TextStyle(
        fontSize: cellSize * 0.25, // Размер шрифта относительно ячейки
        color: Colors.black,
      );

      final tp = _getTextPainter(label, style);

      // Подписи для колонок (сверху)
      canvas.save();

      // Перемещаемся к верхней части колонки
      canvas.translate(
        axisOffset + i * cellSize + cellSize / 2,
        axisOffset - 6,
      );

      canvas.rotate(angle); // Поворачиваем для лучшей читаемости

      tp.paint(
        canvas,
        Offset(-tp.width / 2 + 37, -tp.height), // Смещение для повернутого текста
      );

      canvas.restore();

      // Подписи для строк
      tp.paint(
        canvas,
        Offset(
          -axisOffset, // Слева от сетки
          axisOffset + i * cellSize + cellSize / 2 - tp.height / 2,
        ),
      );
    }

    return recorder.endRecording();
  }


  /// Рисует тултип с информацией о ячейке под курсором.
  void _drawTooltip(Canvas canvas, int row, int col) {
    final axisOffset = cellSize;

    final value = matrix.getByIndex(row, col);
    final rowName = matrix.fieldNames[row];
    final colName = matrix.fieldNames[col];

    final text = "$rowName ↔ $colName\n${value.toStringAsFixed(3)}";

    final style = const TextStyle(
      color: Colors.white,
      fontSize: 12,
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);

    // Позиционируем тултип справа от ячейки
    final x = axisOffset + col * cellSize + cellSize + 6;
    final y = axisOffset + row * cellSize - tp.height / 2;

    // Фон тултипа с отступами
    final rect = Rect.fromLTWH(
      x - 6,
      y - 4,
      tp.width + 12,
      tp.height + 8,
    );

    final bg = Paint()..color = Colors.black;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      bg,
    );

    tp.paint(canvas, Offset(x, y));
  }


  /// Умное сокращение длинных названий полей.
  ///
  /// - Если длина превышает максимум, пытается сократить по символу подчеркивания
  /// - Если не получается, обрезает с многоточием
  String _smartLabel(String text, {int max = 16}) {
    if (text.length <= max) return text;

    final parts = text.split('_');

    if (parts.length > 1) {
      // Берем первые буквы каждой части
      return parts.map((e) => e.characters.first).join();
    }

    return '${text.substring(0, max)}…';
  }

  /// Вычисляет угол наклона подписей в зависимости от размера ячейки.
  ///
  /// При маленьких ячейках поворачиваем сильнее для экономии места.
  double _computeLabelAngle() {
    if (cellSize > 90) return 0;        // Большие ячейки - без наклона
    if (cellSize > 55) return -0.6;     // Средние - небольшой наклон
    return -1.5708;                     // Маленькие - вертикально (-90°)
  }

  /// Вычисляет шаг отображения подписей для перегруженных матриц.
  ///
  /// При маленьких ячейках показываем подписи реже, чтобы избежать наложения.
  int _computeLabelStep() {
    if (cellSize > 39) return 1;         // Крупные ячейки - все подписи
    if (cellSize > 25) return 2;         // Средние - каждую вторую
    return 4;                             // Мелкие - каждую четвертую
  }


  @override
  void paint(Canvas canvas, Size size) {
    final n = matrix.size;
    if (n == 0) return;

    final axisOffset = cellSize;

    // Отрисовка статического слоя (кэшированного)
    _staticLayer ??= _buildStaticLayer();
    canvas.drawPicture(_staticLayer!);

    // Отрисовка ячеек тепловой карты (динамический слой)
    // Этот слой перерисовывается при каждом изменении из-за анимации
    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        // В режиме треугольника пропускаем нижнюю половину
        if (triangleMode && col < row) continue;

        final value = matrix.getByIndex(row, col);

        // Устанавливаем цвет с учетом анимации
        _paint.color = _getAnimatedColor(value);

        final rect = Rect.fromLTWH(
          axisOffset + col * cellSize,
          axisOffset + row * cellSize,
          cellSize,
          cellSize,
        );

        canvas.drawRect(rect, _paint);

        // Отображение значений внутри ячеек
        if (showValues && cellSize > 25) { // Не показываем в слишком мелких ячейках
          final tp = _getTextPainter(
            value.toStringAsFixed(2),
            TextStyle(
              fontSize: cellSize * 0.3,
              // Контрастный цвет текста в зависимости от яркости фона
              color: value.abs() > 0.4 ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
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

    // Подсветка ячейки под курсором и тултип
    if (hoverRow != null && hoverCol != null) {
      final highlightPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(
        Rect.fromLTWH(
          axisOffset + hoverCol! * cellSize,
          axisOffset + hoverRow! * cellSize,
          cellSize,
          cellSize,
        ),
        highlightPaint,
      );
      _drawTooltip(canvas, hoverRow!, hoverCol!);
    }
  }

  // Определение необходимости перерисовки

  @override
  bool shouldRepaint(covariant HeatmapPainter old) {
    // Перерисовываем только если изменились параметры
    return old.matrix != matrix ||
        old.colorMapper != colorMapper ||
        old.previousMapper != previousMapper ||
        old.animationValue != animationValue ||
        old.cellSize != cellSize ||
        old.triangleMode != triangleMode ||
        old.showValues != showValues ||
        old.hoverRow != hoverRow ||
        old.hoverCol != hoverCol;
  }
}