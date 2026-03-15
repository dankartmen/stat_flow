import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/dataset/dataset.dart';
import 'bar_state.dart';

const int _kMaxChartPoints = 5000;

/// {@template bar_view}
/// Виджет для отображения столбчатой диаграммы
/// 
/// Использует SyncFusion Charts для построения интерактивной столбчатой диаграммы
/// с поддержкой:
/// - Отображения распределения категориальных данных
/// - Подписей значений на столбцах
/// - Настраиваемой ширины столбцов
/// {@endtemplate}
class BarView extends StatefulWidget {
  final Dataset dataset;
  final BarState state;

  const BarView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  _BarViewState createState() => _BarViewState();
}


class _BarViewState extends State<BarView> {
  List<BarData> _barData = [];
  bool _isSampled = false;


  @override
  void initState() {
    super.initState();
    _updateData(widget.dataset, widget.state);
  }

  @override
  void didUpdateWidget(covariant BarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    log(oldWidget.state.toString(), name: 'BarView didUpdateWidget - old state');
    log(widget.state.toString(), name: 'BarView didUpdateWidget - new state');
    if (oldWidget.dataset != widget.dataset ||
        oldWidget.state != widget.state) {
      _updateData(widget.dataset, widget.state);
    }
  }

  void _updateData(Dataset dataset, BarState state) {
    log("Обновление данных в BarView с состоянием: ${state.toString()}", name: 'BarView');
    if (state.columnName == null) {
      setState(() {
        _barData = [];
        _isSampled = false;
      });
      return;
    }

    final column = dataset.numeric(state.columnName!);
    final allValues = column.data.whereType<double>().toList();

    if (allValues.isEmpty) {
      setState(() {
        _barData = [];
        _isSampled = false;
      });
      return;
    }

    // Сэмплирование данных для ускорения рендеринга на больших датасетах
    final values = allValues.length > _kMaxChartPoints
        ? allValues.sample(_kMaxChartPoints)
        : allValues;

    setState(() {
      _isSampled = values.length != allValues.length;
      _barData = List.generate(values.length, (index) => BarData('${index + 1}', values[index]));
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_barData.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }

    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SfCartesianChart(
            tooltipBehavior: TooltipBehavior(
              enable: true,
              duration: 2000,
              header: widget.state.columnName ?? 'Столбчатая диаграмма',
              activationMode: ActivationMode.singleTap,
              format: 'Категория: point.x\nЗначение: point.y',
            ),

            primaryXAxis: CategoryAxis(
              title: const AxisTitle(text: 'Категория'),
              labelRotation: 45,
            ),
            
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: widget.state.columnName),
            ),

            series: _buildSeries(),
          ),
        ),
      ],
    );
  }

  List<BarSeries<BarData, String>> _buildSeries() {
    return [
      BarSeries<BarData, String>(
        dataSource: _barData,
        xValueMapper: (data, _) => data.category,
        yValueMapper: (data, _) => data.value,
        width: widget.state.barWidth,
        dataLabelSettings: DataLabelSettings(
          alignment: _getBarAlignment(widget.state.alignment),
          isVisible: widget.state.showValues,
          textStyle: const TextStyle(fontSize: 10),
        ),
      ),
    ];
  }

  // Преобразование BarAlignment в ChartAlignment
  ChartAlignment _getBarAlignment(BarAlignment alignment) {
    switch (alignment) {
      case BarAlignment.far:
        return ChartAlignment.far;
      case BarAlignment.near:
        return ChartAlignment.near;
      case BarAlignment.center:
        return ChartAlignment.center;
    }
  }
}

/// Вспомогательный класс для данных столбчатой диаграммы
class BarData {
  final String category;
  final double value;

  BarData(this.category, this.value);
}