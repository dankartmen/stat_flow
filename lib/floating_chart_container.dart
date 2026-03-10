import 'package:flutter/material.dart';

import 'floating_chart_data.dart';

/// {@template floating_chart}
/// Плавающий контейнер для графика с возможностью перемещения и изменения размера
/// 
/// Предоставляет интерактивный контейнер, который можно:
/// - Перетаскивать по экрану (захватом за заголовок)
/// - Изменять размер (захватом за нижний правый угол)
/// - Выделять (при клике меняется цвет рамки и заголовка)
/// - Разворачивать на весь экран
/// - Закрывать
/// 
/// Используется в системах с плавающими окнами графиков (dashboard).
/// {@endtemplate}
class FloatingChart extends StatefulWidget {
  /// Данные плавающего графика
  final FloatingChartData data;

  /// Флаг выделения (активен ли текущий график)
  final bool isSelected;

  /// Callback при выборе графика
  final VoidCallback onSelect;

  /// Callback при изменении позиции
  final Function(Offset) onPositionChanged;

  /// Callback при изменении размера
  final Function(Size) onSizeChanged;

  /// Callback при закрытии графика
  final VoidCallback onClose;

  /// Callback при переходе в полноэкранный режим
  final VoidCallback onFullscreen;

  /// Дочерний виджет (содержимое графика)
  final Widget child;

  /// {@macro floating_chart}
  const FloatingChart({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onSelect,
    required this.onPositionChanged,
    required this.onSizeChanged,
    required this.onClose,
    required this.onFullscreen,
    required this.child,
  });

  @override
  State<FloatingChart> createState() => _FloatingChartState();
}

class _FloatingChartState extends State<FloatingChart> {
  /// Текущая позиция окна
  late Offset _position;

  /// Текущий размер окна
  late Size _size;

  /// Минимальный допустимый размер окна
  final Size _minSize = const Size(400, 300);

  /// Флаг перетаскивания
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.data.position;
    _size = widget.data.size;
  }

  @override
  void didUpdateWidget(FloatingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.position != widget.data.position) {
      _position = widget.data.position;
    }
    if (oldWidget.data.size != widget.data.size) {
      _size = widget.data.size;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      width: _size.width,
      height: _size.height,
      child: GestureDetector(
        onTap: widget.onSelect,
        onPanStart: (_) {
          setState(() => _isDragging = true);
          widget.onSelect();
        },
        onPanUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _position += details.delta;
            });
            widget.onPositionChanged(_position);
          }
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
        },
        child: Material(
          elevation: widget.isSelected ? 12 : 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: widget.isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                /// Заголовок (ручка для захвата)
                _buildHeader(),

                /// Контент графика
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: widget.child,
                  ),
                ),

                /// Хендлер для изменения размера
                _buildResizeHandle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Строит заголовок окна с элементами управления
  /// 
  /// Заголовок выполняет функцию ручки для перетаскивания и содержит:
  /// - Иконку-индикатор перетаскивания
  /// - Название графика (из [ChartType])
  /// - Кнопку полноэкранного режима
  /// - Кнопку закрытия
  Widget _buildHeader() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _position += details.delta;
        });
        widget.onPositionChanged(_position);
        widget.onSelect();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            // Иконка для перетаскивания
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.drag_handle,
                size: 20,
                color: widget.isSelected ? Colors.white : Colors.grey[600],
              ),
            ),

            // Название графика
            Expanded(
              child: Text(
                widget.data.type.name,
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Кнопка полноэкранного режима
            IconButton(
              icon: Icon(
                Icons.open_in_full,
                size: 18,
                color: widget.isSelected ? Colors.white : Colors.grey[600],
              ),
              onPressed: widget.onFullscreen,
            ),

            // Кнопка закрытия
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: widget.isSelected ? Colors.white : Colors.grey[600],
              ),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }

  /// Строит хендлер для изменения размера окна
  /// 
  /// Расположен в правом нижнем углу. При перетаскивании:
  /// - Изменяет ширину и высоту окна
  /// - Ограничивает минимальный размер [_minSize]
  /// - Вызывает callback [onSizeChanged]
  Widget _buildResizeHandle() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newWidth = _size.width + details.delta.dx;
            double newHeight = _size.height + details.delta.dy;

            newWidth = newWidth.clamp(_minSize.width, double.infinity);
            newHeight = newHeight.clamp(_minSize.height, double.infinity);

            _size = Size(newWidth, newHeight);
          });
          widget.onSizeChanged(_size);
          widget.onSelect();
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.blue : Colors.grey[400],
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(8),
              topLeft: Radius.circular(8),
            ),
          ),
          child: Icon(
            Icons.open_in_full,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }
}