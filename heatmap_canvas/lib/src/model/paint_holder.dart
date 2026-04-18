import 'package:flutter/painting.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_config.dart';

/// {@template heatmap_paint_holder}
/// Хранилище всех данных, необходимых для отрисовки одного кадра тепловой карты.
/// 
/// Используется в [HeatmapPainter] и [RenderHeatmap] для передачи:
/// - текущих и целевых данных (для анимации)
/// - значения анимации (0.0 — текущие, 1.0 — целевые)
/// - конфигурации отображения
/// - масштабирования текста
/// 
/// Является иммутабельным — каждый кадр создаёт новый экземпляр.
/// {@endtemplate}
class HeatmapPaintHolder {
  /// Текущие данные тепловой карты.
  final HeatmapData data;
  
  /// Целевые данные для анимации перехода.
  final HeatmapData targetData;
  
  /// Значение анимации от 0.0 до 1.0.
  final double animationValue;
  
  /// Конфигурация отображения.
  final HeatmapConfig config;
  
  /// Масштабировщик текста (из MediaQuery).
  final TextScaler textScaler;

  const HeatmapPaintHolder({
    required this.data,
    required this.targetData,
    required this.animationValue,
    required this.config,
    required this.textScaler,
  });
}