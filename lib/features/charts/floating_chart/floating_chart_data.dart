import 'dart:ui';
import 'package:stat_flow/features/charts/chart_state.dart';
import '../../../core/dataset/dataset.dart';
import '../chart_type.dart';

/// {@template floating_chart_data}
/// Модель данных для плавающего окна графика
/// 
/// Хранит всю необходимую информацию для отображения и управления
/// плавающим окном графика в интерфейсе дашборда:
/// - Уникальный идентификатор
/// - Тип графика
/// - Датасет для отображения
/// - Позиция на экране
/// - Размер окна
/// {@endtemplate}
class FloatingChartData {
  /// Уникальный идентификатор окна
  final int id;

  /// Тип отображаемого графика
  final ChartType type;

  /// Датасет с данными для графика
  final Dataset dataset;

  /// Позиция окна на экране
  final Offset position;

  /// Размер окна
  final Size size;

  /// Состояние графика
  final ChartState state;

  /// {@macro floating_chart_data}
  const FloatingChartData({
    required this.id,
    required this.type,
    required this.dataset,
    required this.state,
    this.position = const Offset(100, 100),
    this.size = const Size(600, 450),
  });

  /// Создает копию объекта с возможностью обновления полей
  /// 
  /// Принимает:
  /// - [id] — новый идентификатор (если нужно изменить)
  /// - [type] — новый тип графика
  /// - [dataset] — новый датасет
  /// - [position] — новую позицию
  /// - [size] — новый размер
  /// 
  /// Возвращает:
  /// - [FloatingChartData] — новый экземпляр с обновленными полями
  FloatingChartData copyWith({
    int? id,
    ChartType? type,
    Dataset? dataset,
    Offset? position,
    Size? size,
    ChartState? state,
  }) {
    return FloatingChartData(
      id: id ?? this.id,
      type: type ?? this.type,
      dataset: dataset ?? this.dataset,
      position: position ?? this.position,
      size: size ?? this.size,
      state: state ?? this.state,
    );
  }
}