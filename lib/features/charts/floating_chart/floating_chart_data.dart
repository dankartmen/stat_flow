import 'dart:ui';
import 'package:stat_flow/features/charts/chart_state.dart';
import '../../../core/dataset/dataset.dart';
import '../chart_type.dart';

/// {@template floating_chart_data}
/// Модель данных для плавающего окна графика.
/// 
/// Хранит всю необходимую информацию для отображения и управления
/// плавающим окном графика в интерфейсе дашборда:
/// - Уникальный идентификатор
/// - Тип графика
/// - Датасет для отображения
/// - Позиция на экране
/// - Размер окна
/// - Состояние графика (настройки)
/// - Колбэки для взаимодействия (тап по ячейке, обновление состояния)
/// {@endtemplate}
class FloatingChartData {
  /// Уникальный идентификатор окна.
  final int id;

  /// Тип отображаемого графика.
  final ChartType type;

  /// Датасет с данными для графика.
  final Dataset dataset;

  /// Позиция окна на экране (левая верхняя точка).
  final Offset position;

  /// Размер окна в пикселях.
  final Size size;

  /// Состояние графика (настройки отображения).
  final ChartState state;

  /// Колбэк, вызываемый при тапе на ячейку графика.
  /// 
  /// Принимает:
  /// - [xCol] — имя колонки по оси X
  /// - [yCol] — имя колонки по оси Y
  final void Function(String xCol, String yCol)? onCellTap;

  /// Колбэк, вызываемый при обновлении состояния графика.
  final void Function(ChartState)? onUpdateState;
  
  /// {@macro floating_chart_data}
  const FloatingChartData({
    required this.id,
    required this.type,
    required this.dataset,
    this.position = const Offset(100, 100),
    this.size = const Size(600, 450),
    required this.state,
    this.onCellTap,
    this.onUpdateState,
  });

  /// Создаёт копию объекта с возможностью обновления полей.
  /// 
  /// Принимает:
  /// - [id] — новый идентификатор (если нужно изменить)
  /// - [type] — новый тип графика
  /// - [dataset] — новый датасет
  /// - [position] — новую позицию
  /// - [size] — новый размер
  /// - [state] — новое состояние
  /// - [onCellTap] — новый колбэк тапа
  /// - [onUpdateState] — новый колбэк обновления состояния
  /// 
  /// Возвращает:
  /// - [FloatingChartData] — новый экземпляр с обновлёнными полями
  FloatingChartData copyWith({
    int? id,
    ChartType? type,
    Dataset? dataset,
    Offset? position,
    Size? size,
    ChartState? state,
    void Function(String xCol, String yCol)? onCellTap,
    void Function(ChartState)? onUpdateState,
  }) {
    return FloatingChartData(
      id: id ?? this.id,
      type: type ?? this.type,
      dataset: dataset ?? this.dataset,
      position: position ?? this.position,
      size: size ?? this.size,
      state: state ?? this.state,
      onCellTap: onCellTap ?? this.onCellTap,
      onUpdateState: onUpdateState ?? this.onUpdateState,
    );
  }
}