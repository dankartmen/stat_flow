import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'scatter_state.dart';

const int _kMaxChartPoints = 5000;

/// {@template scatter_view}
/// Виджет для отображения диаграммы рассеяния (scatter plot)
/// 
/// Использует SyncFusion Charts для построения интерактивного scatter plot
/// с поддержкой:
/// - Отображения зависимости между двумя числовыми колонками
/// - Всплывающих подсказок (tooltips) с координатами точки
/// - Адаптивного отображения под разные размеры
/// 
/// Требует две выбранные числовые колонки в [ScatterState].
/// {@endtemplate}
class ScatterView extends StatelessWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние диаграммы рассеяния с настройками
  final ScatterState state;

  /// {@macro scatter_view}
  const ScatterView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Проверка выбора колонок
    if (state.firstColumnName == null || state.secondColumnName == null) {
      return const Center(
        child: Text("Выберите колонки для осей X и Y"),
      );
    }

    // Получение числовых колонок
    final firstColumn = dataset.numeric(state.firstColumnName!);
    final secondColumn = dataset.numeric(state.secondColumnName!);
    log("Построение scatter plot для колонок: ${firstColumn.name} и ${secondColumn.name}");
    // Фильтрация null-значений и подготовка пар данных
    final allPoints = <_ScatterPoint>[];

    for (int i = 0; i < firstColumn.data.length; i++) {
      final xValue = firstColumn.data[i];
      final yValue = i < secondColumn.data.length ? secondColumn.data[i] : null;

      if (xValue != null && yValue != null) {
        allPoints.add(_ScatterPoint(xValue, yValue));
      }
    }

    // Проверка наличия данных
    if (allPoints.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }

    // Сэмплирование для ускорения рендеринга
    final points = allPoints.length > _kMaxChartPoints
        ? allPoints.sample(_kMaxChartPoints)
        : allPoints;
    final isSampled = points.length != allPoints.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSampled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Показано ${points.length} из ${allPoints.length} точек (сэмплирование)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Expanded(
          child: SfCartesianChart(
            // Настройка всплывающих подсказок
            tooltipBehavior: TooltipBehavior(
              enable: true,
              duration: 2000,
              header: '${firstColumn.name} vs ${secondColumn.name}',
              activationMode: ActivationMode.singleTap,
              format: 'X: point.x\nY: point.y',
            ),

            // Настройка осей
            primaryXAxis: NumericAxis(
              title: AxisTitle(text: firstColumn.name),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: secondColumn.name),
            ),

            // Серия данных - scatter plot
            series: <ScatterSeries<_ScatterPoint, double>>[
              ScatterSeries<_ScatterPoint, double>(
                dataSource: points,
                xValueMapper: (_ScatterPoint point, _) => point.x,
                yValueMapper: (_ScatterPoint point, _) => point.y,
                enableTooltip: true,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  shape: DataMarkerType.circle,
                  width: 8,
                  height: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Вспомогательный класс для хранения точки данных
class _ScatterPoint {
  final double x;
  final double y;

  _ScatterPoint(this.x, this.y);
}