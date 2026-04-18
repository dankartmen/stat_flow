import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'heatmap_config.dart';

/// {@template heatmap_touch_data}
/// Конфигурация обработки касаний и наведения для тепловой карты.
/// 
/// Управляет:
/// - Включением/выключением обработки событий
/// - Колбэками при касаниях и наведении
/// - Встроенными тултипами и подсветкой
/// - Курсором мыши при наведении на ячейки
/// {@endtemplate}
class HeatmapTouchData with EquatableMixin {
  /// Включает/выключает всю обработку касаний.
  final bool enabled;

  /// Порог расстояния в пикселях для захвата ячейки (для тач-устройств).
  final double touchSpotThreshold;

  /// Колбэк, вызываемый при событиях касания/наведения.
  /// 
  /// Принимает:
  /// - [event] — обёртка над PointerEvent
  /// - [response] — информация о ячейке под курсором (или null)
  final BaseTouchCallback<HeatmapTouchResponse>? touchCallback;

  /// Определяет, должен ли встроенный обработчик показывать тултип и подсветку.
  /// 
  /// Если false, вся встроенная визуальная обратная связь отключается,
  /// но [touchCallback] продолжает вызываться.
  final bool handleBuiltInTouches;

  /// Настройки встроенного тултипа.
  final HeatmapTouchTooltipData touchTooltipData;

  /// Резолвер курсора мыши.
  /// 
  /// Позволяет кастомизировать курсор в зависимости от ячейки под ним.
  final MouseCursorResolver<HeatmapTouchResponse>? mouseCursorResolver;

  const HeatmapTouchData({
    this.enabled = true,
    this.touchSpotThreshold = 10.0,
    this.touchCallback,
    this.handleBuiltInTouches = true,
    this.touchTooltipData = const HeatmapTouchTooltipData(),
    this.mouseCursorResolver,
  });

  HeatmapTouchData copyWith({
    bool? enabled,
    double? touchSpotThreshold,
    BaseTouchCallback<HeatmapTouchResponse>? touchCallback,
    bool? handleBuiltInTouches,
    HeatmapTouchTooltipData? touchTooltipData,
    MouseCursorResolver<HeatmapTouchResponse>? mouseCursorResolver,
  }) {
    return HeatmapTouchData(
      enabled: enabled ?? this.enabled,
      touchSpotThreshold: touchSpotThreshold ?? this.touchSpotThreshold,
      touchCallback: touchCallback ?? this.touchCallback,
      handleBuiltInTouches: handleBuiltInTouches ?? this.handleBuiltInTouches,
      touchTooltipData: touchTooltipData ?? this.touchTooltipData,
      mouseCursorResolver: mouseCursorResolver ?? this.mouseCursorResolver,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        touchSpotThreshold,
        handleBuiltInTouches,
        touchTooltipData,
        // touchCallback и mouseCursorResolver - функции, исключаем
      ];
}

/// {@template heatmap_touch_tooltip_data}
/// Настройки встроенного тултипа при касании/наведении на ячейку.
/// 
/// Управляет внешним видом и поведением всплывающей подсказки.
/// {@endtemplate}
class HeatmapTouchTooltipData with EquatableMixin {
  /// Внутренний отступ содержимого тултипа.
  final EdgeInsetsGeometry padding;

  /// Отступ тултипа от ячейки в пикселях.
  final double tooltipMargin;

  /// Максимальная ширина тултипа.
  final double maxContentWidth;

  /// Принудительно умещать тултип по горизонтали внутри графика.
  final bool fitInsideHorizontally;

  /// Принудительно умещать тултип по вертикали внутри графика.
  final bool fitInsideVertically;

  /// Цвет фона тултипа.
  final Color? backgroundColor;

  /// Радиус скругления углов тултипа.
  final BorderRadius? borderRadius;

  /// Кастомный билдер содержимого тултипа.
  /// 
  /// Если задан, используется вместо стандартного текста.
  /// Позволяет отображать сложные виджеты (графики, иконки, форматированный текст).
  final Widget Function(BuildContext context, HeatmapCell cell)? contentBuilder;

  const HeatmapTouchTooltipData({
    this.padding = const EdgeInsets.all(8.0),
    this.tooltipMargin = 8.0,
    this.maxContentWidth = 120.0,
    this.fitInsideHorizontally = true,
    this.fitInsideVertically = true,
    this.backgroundColor,
    this.borderRadius,
    this.contentBuilder,
  });

  HeatmapTouchTooltipData copyWith({
    EdgeInsetsGeometry? padding,
    double? tooltipMargin,
    double? maxContentWidth,
    bool? fitInsideHorizontally,
    bool? fitInsideVertically,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Widget Function(BuildContext context, HeatmapCell cell)? contentBuilder,
  }) {
    return HeatmapTouchTooltipData(
      padding: padding ?? this.padding,
      tooltipMargin: tooltipMargin ?? this.tooltipMargin,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      fitInsideHorizontally: fitInsideHorizontally ?? this.fitInsideHorizontally,
      fitInsideVertically: fitInsideVertically ?? this.fitInsideVertically,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      contentBuilder: contentBuilder ?? this.contentBuilder,
    );
  }

  @override
  List<Object?> get props => [
        padding,
        tooltipMargin,
        maxContentWidth,
        fitInsideHorizontally,
        fitInsideVertically,
        backgroundColor,
        borderRadius,
        contentBuilder,
      ];
}

/// Тип колбэка для обработки касаний.
typedef BaseTouchCallback<T> = void Function(FlTouchEvent event, T? response);

/// {@template heatmap_touch_response}
/// Информация о событии касания/наведения для тепловой карты.
/// 
/// Содержит координаты касания и данные о ячейке под курсором.
/// {@endtemplate}
class HeatmapTouchResponse with EquatableMixin {
  /// Глобальные координаты касания (относительно экрана).
  final Offset? touchLocation;

  /// Координаты касания в системе координат графика.
  final Offset? touchChartCoordinate;

  /// Информация о ячейке под указателем (или null, если указатель вне ячеек).
  final HeatmapCell? cell;

  const HeatmapTouchResponse({
    this.touchLocation,
    this.touchChartCoordinate,
    this.cell,
  });

  HeatmapTouchResponse copyWith({
    Offset? touchLocation,
    Offset? touchChartCoordinate,
    HeatmapCell? cell,
  }) {
    return HeatmapTouchResponse(
      touchLocation: touchLocation ?? this.touchLocation,
      touchChartCoordinate: touchChartCoordinate ?? this.touchChartCoordinate,
      cell: cell ?? this.cell,
    );
  }

  @override
  List<Object?> get props => [touchLocation, touchChartCoordinate, cell];
}

/// {@template fl_touch_event}
/// Класс-обёртка для событий Flutter (мышь/касание/стилус).
/// {@endtemplate}
class FlTouchEvent {
  /// Исходное событие указателя от Flutter.
  final PointerEvent pointerEvent;
  
  const FlTouchEvent(this.pointerEvent);
}

/// Резолвер курсора мыши.
typedef MouseCursorResolver<T> = MouseCursor Function(FlTouchEvent event, T? response);