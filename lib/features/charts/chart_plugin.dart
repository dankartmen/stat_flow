import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/chart_type.dart';
import 'chart_state.dart';
import 'floating_chart/floating_chart_data.dart';

/// {@template chart_plugin}
/// Абстрактный базовый класс для плагинов графиков
/// 
/// Определяет контракт, который должен реализовать каждый тип графика:
/// - Уникальный идентификатор типа
/// - Создание начального состояния
/// - Построение виджета графика
/// - Построение панели управления
/// 
/// Плагины регистрируются в [ChartRegistry] и используются для
/// динамического создания графиков и их элементов управления.
/// {@endtemplate}
abstract class ChartPlugin {
  /// {@macro chart_plugin}
  const ChartPlugin();

  /// Уникальный идентификатор типа графика
  /// 
  /// Должен соответствовать одному из значений [ChartType]
  ChartType get type;

  /// Создает начальное состояние для графика этого типа
  /// 
  /// Возвращает объект, наследующий [ChartState], который хранит
  /// специфичные для графика настройки (палитра, режимы отображения и т.д.)
  ChartState createState();

  /// Строит виджет графика на основе данных
  /// 
  /// Принимает:
  /// - [data] — данные плавающего графика (включая датасет и состояние)
  /// 
  /// Возвращает:
  /// - [Widget] — виджет для отображения в плавающем окне
  Widget buildChart(FloatingChartData data);

  /// Строит панель управления для графика
  /// 
  /// Принимает:
  /// - [data] — данные плавающего графика
  /// - [refresh] — callback для обновления UI при изменении настроек
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в [TopControlPanel]
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
  );
}