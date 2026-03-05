import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_legend.dart';

import '../model/correlation_clusterer.dart';
import '../model/correlation_matrix.dart';
import '../color/heatmap_color_mapper.dart';
import '../painter/heatmap_painter.dart';
import '../color/heatmap_palette.dart';
import 'heatmap_controls.dart';

/// {@template heatmap_view}
/// Основной виджет для отображения интерактивной тепловой карты
/// с поддержкой настройки цветов, кластеризации и анимации.
/// {@endtemplate}
class HeatmapView extends StatefulWidget {
  /// Матрица корреляции для отображения
  final CorrelationMatrix matrix;

  /// {@macro heatmap_view}
  const HeatmapView({
    super.key,
    required this.matrix,
  });

  @override
  State<HeatmapView> createState() => _HeatmapViewState();
}

class _HeatmapViewState extends State<HeatmapView>
    with SingleTickerProviderStateMixin {
  // Состояние интерактивности
  int? hoverRow;
  int? hoverCol;
  Offset? hoverPosition;
  double selectedStep = 0.2;
  
  // Настройки отображения
  HeatmapColorMode colorMode = HeatmapColorMode.discrete;
  bool clusterEnabled = false;
  
  // Мапперы и анимация
  late HeatmapColorMapper _currentMapper;
  late AnimationController _controller;
  late HeatmapPalette _palette;
  late int _segments;
  late bool _triangleMode;
  late HeatmapColorMapper _previousMapper;
  
  // Кэшированная кластеризованная матрица
  CorrelationMatrix? _clusteredMatrix;

  @override
  void initState() {
    super.initState();
    _palette = HeatmapPalette.redBlue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _segments = 10;
    _triangleMode = false;
    _currentMapper = _createMapper();
    _previousMapper = _currentMapper;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matrix.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Панель управления
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12)
          ),
          child: HeatmapControls(
            upperTriangle: _triangleMode,
            onUpperTriangleChanged: _updateTriangle,
            segments: _segments,
            onSegmentsChanged: _updateSegments,
            palette: _palette,
            onPaletteChanged: _updatePallete,
            colorMode: colorMode,
            onColorModeChanged: _updateColorMode,
            clusterEnabled: clusterEnabled,
            onClusterPressed: _toggleCluster,
          ),
        ),
        
        const SizedBox(height: 12),

        // Тепловая карта с прокруткой
        SizedBox(
          height: 600,
          child: ClipRect(child: _buildHeatmap()),
        ),
        
        
        // Легенда
        HeatmapLegend(
          mapper: _currentMapper,   
          min: -1, 
          max: 1, 
          segments: _segments
        ),
      ],
    );
  }
  
  /// Создание маппера цветов на основе текущих настроек
  HeatmapColorMapper _createMapper() {
    switch (colorMode) {
      case HeatmapColorMode.discrete:
        final base = HeatmapPaletteFactory.baseColors(_palette);

        return DiscreteColorMapper(
          min: -1,
          max: 1,
          segments: _segments,
          baseColors: base,
        );

      case HeatmapColorMode.gradient:
        return GradientColorMapper(
          paletteType: _palette,
        );
    }
  }

  /// Обновление цветовой палитры с анимацией
  void _updatePallete(HeatmapPalette palette) {
    setState(() {
      _palette = palette;
      _previousMapper = _currentMapper;
      _currentMapper = _createMapper();
      _controller.forward(from: 0);
    });
  }

  /// Обновление количества сегментов
  void _updateSegments(int segments) {
    setState(() {
      _segments = segments;
      _previousMapper = _currentMapper;
      _currentMapper = _createMapper(); 
    });
  }

  /// Обновление режима треугольника
  void _updateTriangle(bool value) {
    setState(() {
      _triangleMode = value;
    });
  }

  /// Обновление режима цветов с анимацией
  void _updateColorMode(HeatmapColorMode mode) {
    setState(() {
      colorMode = mode;
      _previousMapper = _currentMapper;
      _currentMapper = _createMapper();
      _controller.forward(from: 0);
    });
  }

  /// Переключение режима кластеризации
  void _toggleCluster() {
    setState(() {
      clusterEnabled = !clusterEnabled;
      _clusteredMatrix = null;
    });
  }

  /// Получение актуальной матрицы для отображения
  /// (исходной или кластеризованной)
  CorrelationMatrix _getDisplayMatrix() {
    if (!clusterEnabled) return widget.matrix;

    _clusteredMatrix ??=
        CorrelationClusterer.cluster(widget.matrix);

    return _clusteredMatrix!;
  }

  /// Построение виджета тепловой карты с поддержкой масштабирования
  Widget _buildHeatmap() {
    final matrix = _getDisplayMatrix();

    const double cellSize = 40;

    final totalSize = matrix.size * cellSize;

    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 5,
      trackpadScrollCausesScale: false,
      boundaryMargin: const EdgeInsets.all(40),
      child: AnimatedBuilder(
        animation: _controller,
        builder:(context, child) => CustomPaint(
          size: Size(totalSize, totalSize),
          painter: HeatmapPainter(
            matrix: _getDisplayMatrix(),
            colorMapper: _currentMapper,
            previousMapper: _previousMapper,
            animationValue: _controller.value,
            cellSize: cellSize,
            showValues: true,
            triangleMode: _triangleMode,
          ),
        ),
      ),
    );
  }
}