import 'package:flutter/material.dart';
import '../chart/heatmap_leaf.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../controller/heatmap_legend_controller.dart';
import '../model/heatmap_config.dart';
import '../model/heatmap_data.dart';
import '../model/hover_range.dart';
import 'heatmap_legend.dart';


/// {@template heatmap_data_tween}
/// Анимационный твин для плавного перехода между двумя наборами данных [HeatmapData].
/// 
/// Выполняет линейную интерполяцию значений каждой ячейки между начальным и конечным состоянием.
/// 
/// Ограничения:
/// - Размеры матриц (количество строк и столбцов) должны совпадать.
/// - При несовпадении размеров анимация невозможна, возвращается конечное состояние.
/// {@endtemplate}
class HeatmapDataTween extends Tween<HeatmapData> {
  /// {@macro heatmap_data_tween}
  HeatmapDataTween({required super.begin, required super.end});

  @override
  HeatmapData lerp(double t) {
    if (begin == null || end == null) return end!;
    
    // Проверка совместимости размеров матриц
    if (begin!.rowLabels.length != end!.rowLabels.length ||
        begin!.columnLabels.length != end!.columnLabels.length) {
      return end!;
    }
    
    // Интерполяция значений каждой ячейки
    final lerpedValues = List.generate(begin!.values.length, (i) {
      return List.generate(begin!.values[i].length, (j) {
        return lerpDouble(begin!.values[i][j], end!.values[i][j], t)!;
      });
    });
    
    return HeatmapData(
      rowLabels: end!.rowLabels,
      columnLabels: end!.columnLabels,
      values: lerpedValues,
    );
  }
}

/// Линейная интерполяция между двумя числами с поддержкой null.
/// 
/// Принимает:
/// - [a] - начальное значение (может быть null)
/// - [b] - конечное значение (может быть null)
/// - [t] - коэффициент интерполяции от 0.0 до 1.0
/// 
/// Возвращает:
/// - интерполированное значение
/// - null, если оба аргумента null
/// 
/// Примечание: null значения интерпретируются как 0.0 для упрощения анимации.
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}

/// {@template heatmap}
/// Интерактивная тепловая карта с поддержкой масштабирования, анимации и кастомизации.
///
/// Основные возможности:
/// - Масштабирование и панорамирование через [InteractiveViewer]
/// - Подсветка ячеек при наведении мыши
/// - Плавная анимация при изменении цветовой схемы или данных
/// - Легенда поверх карты (в правом верхнем углу)
/// - Автоматическое усечение подписей осей
/// - Умное позиционирование тултипов с учётом границ экрана
/// - Анимация переходов между состояниями (длительность 350 мс по умолчанию)
///
/// Пример использования:
/// ```dart
/// Heatmap(
///   data: myHeatmapData,
///   config: HeatmapConfig(
///     palette: HeatmapPalette.redBlue,
///     showValues: true,
///   ),
///   duration: Duration(milliseconds: 500),
/// )
/// ```
/// {@endtemplate}
class Heatmap extends ImplicitlyAnimatedWidget {
  /// Данные для отображения (обязательно).
  /// 
  /// Содержит матрицу значений и подписи строк/столбцов.
  final HeatmapData data;

  /// Конфигурация отображения.
  /// 
  /// Управляет цветами, сортировкой, подписями, обработкой касаний и др.
  final HeatmapConfig config;


  /// {@macro heatmap_canvas.heatmap}
  const Heatmap({
    super.key,
    required this.data,
    this.config = const HeatmapConfig(),
    super.duration = const Duration(milliseconds: 350),
    super.curve = Curves.linear,
  });

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _HeatmapState();
}

/// {@template heatmap_state}
/// Состояние виджета [Heatmap].
/// 
/// Управляет анимацией данных, синхронизацией с легендой и обновлением при изменении конфигурации.
/// {@endtemplate}
class _HeatmapState extends AnimatedWidgetBaseState<Heatmap> {
  /// Анимация данных между состояниями.
  HeatmapDataTween? _dataTween;

  /// Контроллер для взаимодействия с легендой (подсветка при наведении)
  late final HeatmapLegendController _legendController = HeatmapLegendController();

  /// Текущий диапазон подсветки из легенды.
  HoverRange? _legendHoverRange;

  @override
  void initState() {
    super.initState();
    _legendController.addListener(_onLegendChanged);
  }
  
  @override
  void didUpdateWidget(covariant Heatmap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final colorChanged = oldWidget.config.palette != widget.config.palette ||
        oldWidget.config.colorMode != widget.config.colorMode ||
        oldWidget.config.customPaletteColors != widget.config.customPaletteColors ||
        oldWidget.config.segments != widget.config.segments;

    if (colorChanged) {
      // Перезапускаем анимацию, чтобы цвета тоже анимировались
      controller.forward(from: 0.0);
    }
  }
  
  @override
  void dispose() {
    _legendController.removeListener(_onLegendChanged);
    _legendController.dispose();
    super.dispose();
  }
  
  /// Обработчик изменения состояния легенды.
  /// 
  /// При наведении на легенду обновляет диапазон подсветки ячеек.
  void _onLegendChanged() {
    setState(() {
      _legendHoverRange = _legendController.hoverRange;
    });
  }
  
  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _dataTween = visitor(
      _dataTween,
      widget.data,
      (value) => HeatmapDataTween(begin: value as HeatmapData, end: widget.data),
    ) as HeatmapDataTween?;
  }

  /// Строит виджет легенды на основе текущих данных и конфигурации.
  /// 
  /// Принимает:
  /// - [data] - текущие анимированные данные
  /// 
  /// Возвращает:
  /// - кастомную легенду, если задан [legendBuilder]
  /// - стандартную [HeatmapLegend] в остальных случаях
  Widget _buildLegend(HeatmapData data) {
    // Используем кастомный билдер легенды, если он предоставлен
    if (widget.config.legendBuilder != null) {
      return widget.config.legendBuilder!(context, _legendController);
    }

    // Получаем цвета палитры из конфигурации
    final paletteColors = HeatmapPaletteFactory.baseColors(
      widget.config.palette,
      customColors: widget.config.customPaletteColors,
    );

    // Создаём маппер цветов (аналогичный используемому в HeatmapPainter)
    final mapper = widget.config.colorMode == HeatmapColorMode.discrete
        ? DiscreteColorMapper(
            min: data.min,
            max: data.max,
            segments: widget.config.segments,
            baseColors: paletteColors,
          )
        : GradientColorMapper(
            paletteType: widget.config.palette,
            min: data.min,
            max: data.max,
          );

    return HeatmapLegend(
      mapper: mapper,
      colorMode: widget.config.colorMode,
      min: data.min,
      max: data.max,
      segments: widget.config.segments,
      onHover: (range) {
      },
      controller: _legendController,
      legendData: widget.config.legend,
    );
  }


  @override
  Widget build(BuildContext context) {
    // Получаем текущие анимированные данные
    final animatedData = _dataTween?.evaluate(animation) ?? widget.data;
    final targetData = widget.data;
    final rowCount = animatedData.rowLabels.length;
    final colCount = animatedData.columnLabels.length;

    // Отображаем сообщение при отсутствии данных
    if (rowCount == 0 || colCount == 0) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    // Создаём тепловую карту с репайнт-границей для оптимизации производительности
    Widget chart = RepaintBoundary(
      child: HeatmapLeaf(
        data: animatedData,
        targetData: targetData,
        animationValue: animation.value,
        config: widget.config,
        hoverRange: _legendHoverRange,
      ),
    );


    final legend = _buildLegend(animatedData);
    
    // Размещаем легенду поверх тепловой карты в правом верхнем углу

    return Stack(
      children: [
        Positioned.fill(child: chart),
        Positioned(top: 12, right: 12, child: legend),
      ],
    );
    
  }
}