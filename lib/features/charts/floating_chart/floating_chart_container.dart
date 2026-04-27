import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'floating_chart_data.dart';

/// {@template floating_chart}
/// Плавающий контейнер для графика с возможностью перемещения и изменения размера
/// 
/// Предоставляет интерактивное окно с:
/// - Заголовком для перетаскивания
/// - Зонами изменения размера по краям и углам
/// - Кнопками полноэкранного режима и закрытия
/// - Автоматическим ограничением позиции в пределах рабочей области
/// 
/// Поддерживает 8 направлений изменения размера через специальные зоны.
/// {@endtemplate}
class FloatingChart extends StatefulWidget {
  /// Данные плавающего графика
  final FloatingChartData data;

  /// Флаг выделения (активен ли текущий график)
  final bool isSelected;

  /// Callback при изменении позиции
  final ValueChanged<Offset> onPositionChanged;

  /// Callback при изменении размера
  final ValueChanged<Size> onSizeChanged;

  /// Callback при выборе графика
  final VoidCallback onSelect;

  /// Callback при закрытии графика
  final VoidCallback onClose;

  /// Callback при переходе в полноэкранный режим
  final VoidCallback onFullscreen;

  /// Дочерний виджет (содержимое графика)
  final Widget child;

  /// Границы рабочей области (опционально)
  final Size? bounds;

  /// {@macro floating_chart}
  const FloatingChart({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onPositionChanged,
    required this.onSizeChanged,
    required this.onSelect,
    required this.onClose,
    required this.onFullscreen,
    required this.child,
    this.bounds,
  });

  /// Создает копию виджета с указанными границами
  /// 
  /// Используется в [CanvasWorkspace] для передачи границ области.
  FloatingChart withBounds(Size bounds) {
    return FloatingChart(
      key: key,
      data: data,
      isSelected: isSelected,
      onPositionChanged: onPositionChanged,
      onSizeChanged: onSizeChanged,
      onSelect: onSelect,
      onClose: onClose,
      onFullscreen: onFullscreen,
      bounds: bounds,
      child: child,
    );
  }

  @override
  State<FloatingChart> createState() => _FloatingChartState();
}

class _FloatingChartState extends State<FloatingChart> {
  /// Ключ для получения рендер-объекта графика при экспорте в PNG
  final GlobalKey _chartKey = GlobalKey();
  static const double _resizeMargin = 12.0;
  static const double _headerHeight = 36.0;
  final Size _minSize = const Size(100, 200);

  late Offset _position;
  late Size _size;

  @override
  void initState() {
    super.initState();
    _position = widget.data.position;
    _size = widget.data.size;
  }

  @override
  void didUpdateWidget(covariant FloatingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final posChanged = oldWidget.data.position != widget.data.position;
    final sizeChanged = oldWidget.data.size != widget.data.size;
    final stateChanged = oldWidget.data.state != widget.data.state;
    final selectedChanged = oldWidget.isSelected != widget.isSelected;
    
    debugPrint('[FloatingChart] didUpdateWidget id=${widget.data.id}: '
        'posChanged=$posChanged, sizeChanged=$sizeChanged, stateChanged=$stateChanged, selectedChanged=$selectedChanged');
    
    if (posChanged) _position = widget.data.position;
    if (sizeChanged) _size = widget.data.size;
  }

  /// Возвращает границы рабочей области или очень большое значение по умолчанию
  Size get _bounds => widget.bounds ?? const Size(100000, 100000);

  /// Перемещает окно с учетом границ области
  void _move(DragUpdateDetails d) {
    double newX = (_position.dx + d.delta.dx).clamp(0, _bounds.width - _size.width);
    double newY = (_position.dy + d.delta.dy).clamp(0, _bounds.height - _size.height);
    setState(() => _position = Offset(newX, newY));
    widget.onPositionChanged(_position);
  }

  /// Изменяет размер окна в указанном направлении
  /// 
  /// Принимает:
  /// - [dir] — направление изменения размера
  /// - [d] — детали перетаскивания
  /// 
  /// Особенности:
  /// - Учитывает минимальный размер [_minSize]
  /// - Ограничивает размер границами области
  /// - Обновляет позицию при изменении размера от левого/верхнего края
  void _resize(_ResizeDirection dir, DragUpdateDetails d) {
    double dx = d.delta.dx, dy = d.delta.dy;
    double newWidth = _size.width, newHeight = _size.height;
    double newX = _position.dx, newY = _position.dy;

    switch (dir) {
      case _ResizeDirection.right:
        newWidth += dx;
        break;
      case _ResizeDirection.left:
        newWidth -= dx;
        newX += dx;
        break;
      case _ResizeDirection.bottom:
        newHeight += dy;
        break;
      case _ResizeDirection.top:
        newHeight -= dy;
        newY += dy;
        break;
      case _ResizeDirection.topLeft:
        newWidth -= dx;
        newHeight -= dy;
        newX += dx;
        newY += dy;
        break;
      case _ResizeDirection.topRight:
        newWidth += dx;
        newHeight -= dy;
        newY += dy;
        break;
      case _ResizeDirection.bottomLeft:
        newWidth -= dx;
        newHeight += dy;
        newX += dx;
        break;
      case _ResizeDirection.bottomRight:
        newWidth += dx;
        newHeight += dy;
        break;
    }

    newWidth = newWidth.clamp(_minSize.width, _bounds.width - newX);
    newHeight = newHeight.clamp(_minSize.height, _bounds.height - newY);

    setState(() {
      _size = Size(newWidth, newHeight);
      _position = Offset(newX, newY);
    });

    widget.onSizeChanged(_size);
    widget.onPositionChanged(_position);
  }

  /// Создает зону для изменения размера
  /// 
  /// Принимает:
  /// - [direction] — направление изменения размера
  /// - [cursor] — курсор мыши при наведении
  /// - Параметры позиционирования (left, right, top, bottom, width, height)
  Widget _resizeZone({
    required _ResizeDirection direction,
    required MouseCursor cursor,
    double? left, double? right, double? top, double? bottom, double? width, double? height,
  }) {
    return Positioned(
      left: left, right: right, top: top, bottom: bottom, width: width, height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (d) => _resize(direction, d),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[FloatingChart] build id=${widget.data.id}, pos=${_position}, size=${_size}, isSelected=${widget.isSelected}');
    final theme = Theme.of(context);
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: SizedBox(
        width: _size.width,
        height: _size.height,
        child: Material(
          elevation: widget.isSelected ? 12 : 4,
          child: Stack(
            children: [
              // Основной контейнер с содержимым
              GestureDetector(
                onTap: widget.onSelect,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: widget.isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _header(),
                      Expanded(
                        child: RepaintBoundary(
                          key: _chartKey,
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Зоны изменения размера по сторонам
              _resizeZone(
                direction: _ResizeDirection.left, 
                cursor: SystemMouseCursors.resizeLeftRight, 
                left: 0, 
                top: 0, 
                bottom: 0, 
                width: _resizeMargin
              ),
              _resizeZone(
                direction: _ResizeDirection.right, 
                cursor: SystemMouseCursors.resizeLeftRight, 
                right: 0, 
                top: 0, 
                bottom: 0, 
                width: _resizeMargin
              ),
              _resizeZone(
                direction: 
                _ResizeDirection.top, 
                cursor: SystemMouseCursors.resizeUpDown, 
                top: 0, 
                left: 0, 
                right: 0, 
                height: _resizeMargin
              ),
              _resizeZone(
                direction: _ResizeDirection.bottom, 
                cursor: SystemMouseCursors.resizeUpDown, 
                bottom: 0, 
                left: 0, 
                right: 0, 
                height: _resizeMargin
              ),

              // Зоны изменения размера по углам
              _resizeZone(
                direction: _ResizeDirection.topLeft, 
                cursor: SystemMouseCursors.resizeUpLeftDownRight, 
                left: 0, 
                top: 0, 
                width: _resizeMargin, 
                height: _resizeMargin
              ),
              _resizeZone(
                direction: _ResizeDirection.topRight, 
                cursor: SystemMouseCursors.resizeUpRightDownLeft, 
                right: 0, 
                top: 0, 
                width: _resizeMargin, 
                height: _resizeMargin
              ),
              _resizeZone(
                direction: _ResizeDirection.bottomLeft, 
                cursor: SystemMouseCursors.resizeUpRightDownLeft, 
                left: 0, 
                bottom: 0, 
                width: _resizeMargin, 
                height: _resizeMargin
              ),
              _resizeZone(
                direction: _ResizeDirection.bottomRight, 
                cursor: SystemMouseCursors.resizeUpLeftDownRight, 
                right: 0, 
                bottom: 0, 
                width: _resizeMargin, 
                height: _resizeMargin
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит заголовок окна с элементами управления
  Widget _header() {
    return GestureDetector(
      onPanUpdate: _move,
      child: Container(
        height: _headerHeight,
        color: widget.isSelected ? Colors.blue : Colors.grey[200],
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.data.type.name,
                style: TextStyle(color: widget.isSelected ? Colors.white : Colors.black87),
              ),
            ),
            IconButton(
              tooltip: "Полноэкранный режим",
              icon: const Icon(Icons.open_in_full, size: 16),
              onPressed: widget.onFullscreen,
            ),
            IconButton(
              tooltip: "Закрыть",
              icon: const Icon(Icons.close, size: 16),
              onPressed: widget.onClose,
            ),
            IconButton(
              tooltip: "Получить скриншот",
              icon: const Icon(Icons.download),
              onPressed: _exportPng,
            ),
          ],
        ),
      ),
    );
  }

  /// Экспортирует текущее содержимое графика в PNG-файл
  /// Особенности:
  /// - Использует [RepaintBoundary] для получения изображения
  /// - Сохраняет файл в директории документов приложения
  /// - Имя файла включает тип графика и временную метку
  Future<void> _exportPng() async {
    if (_chartKey.currentContext == null) return;
    final boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final timestamp = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    final fileName = "${widget.data.type.name}($timestamp).png";
    final file = File("${dir.path}/$fileName");
    await file.writeAsBytes(byteData.buffer.asUint8List());

    if (!mounted) return;
    
    final snackBar = SnackBar(
      content: Text("Сохранено: ${file.path}"),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Открыть',
        onPressed: () async {
          try {
            await OpenFile.open(file.path);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось открыть файл'), duration: Duration(seconds: 2)),
            );
          }
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

enum _ResizeDirection {
  top, bottom, left, right,
  topLeft, topRight, bottomLeft, bottomRight,
}