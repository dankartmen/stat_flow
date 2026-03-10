import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/color/heatmap_palette.dart';
import 'package:stat_flow/features/charts/heatmap/color/heatmap_color_mapper.dart';

import 'features/charts/chart_type.dart';

/// {@template top_control_panel}
/// Верхняя панель управления для настройки отображения графиков
/// 
/// Отображает контекстные элементы управления в зависимости от типа графика:
/// - Для тепловой карты: выбор палитры, режима раскраски, количества сегментов,
///   отображение верхнего треугольника, включение кластеризации
/// - Для других типов графиков: заглушка "в разработке"
/// 
/// Панель имеет фиксированную высоту 80 пикселей и адаптируется под разные типы графиков.
/// {@endtemplate}
class TopControlPanel extends StatelessWidget {
  /// Тип текущего графика
  final ChartType chartType;

  // Параметры для тепловой карты
  /// Выбранная цветовая палитра
  final HeatmapPalette palette;

  /// Количество сегментов для дискретного режима
  final int segments;

  /// Режим отображения только верхнего треугольника
  final bool triangleMode;

  /// Включение кластеризации
  final bool clusterEnabled;

  /// Режим раскраски (непрерывный/дискретный)
  final HeatmapColorMode colorMode;

  /// Callback при изменении палитры
  final ValueChanged<HeatmapPalette> onPaletteChanged;

  /// Callback при изменении количества сегментов
  final ValueChanged<int> onSegmentsChanged;

  /// Callback при изменении режима треугольника
  final ValueChanged<bool> onTriangleModeChanged;

  /// Callback при изменении состояния кластеризации
  final ValueChanged<bool> onClusterEnabledChanged;

  /// Callback при изменении режима раскраски
  final ValueChanged<HeatmapColorMode> onColorModeChanged;

  /// {@macro top_control_panel}
  const TopControlPanel({
    super.key,
    required this.chartType,
    required this.palette,
    required this.segments,
    required this.triangleMode,
    required this.clusterEnabled,
    required this.colorMode,
    required this.onPaletteChanged,
    required this.onSegmentsChanged,
    required this.onTriangleModeChanged,
    required this.onClusterEnabledChanged,
    required this.onColorModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Информация о выбранном графике
            _buildChartInfo(),

            const SizedBox(width: 24),

            // Панель управления в зависимости от типа графика
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildControls(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит информационный блок о текущем графике
  Widget _buildChartInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getIconForChartType(chartType),
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Управление: ${chartType.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// Возвращает иконку для соответствующего типа графика
  IconData _getIconForChartType(ChartType type) {
    switch (type) {
      case ChartType.heatmap:
        return Icons.heat_pump;
      case ChartType.scatter:
        return Icons.bubble_chart;
      case ChartType.histogram:
        return Icons.bar_chart;
      case ChartType.boxplot:
        return Icons.candlestick_chart;
    }
  }

  /// Строит список элементов управления в зависимости от типа графика
  List<Widget> _buildControls() {
    switch (chartType) {
      case ChartType.heatmap:
        return _buildHeatmapControls();
      default:
        return [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Управление для этого типа графика в разработке'),
          ),
        ];
    }
  }

  /// Строит элементы управления для тепловой карты
  List<Widget> _buildHeatmapControls() {
    return [
      // Выбор палитры
      _ControlItem(
        label: 'Палитра',
        child: DropdownButton<HeatmapPalette>(
          value: palette,
          items: HeatmapPalette.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(
                p.name,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (v) => onPaletteChanged(v!),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
        ),
      ),

      const SizedBox(width: 16),

      // Режим отображения цветов
      _ControlItem(
        label: 'Режим',
        child: DropdownButton<HeatmapColorMode>(
          value: colorMode,
          items: HeatmapColorMode.values.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(
                m.name,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (v) => onColorModeChanged(v!),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
        ),
      ),

      const SizedBox(width: 16),

      // Количество сегментов (только для дискретного режима)
      if (colorMode == HeatmapColorMode.discrete)
        _ControlItem(
          label: 'Сегменты',
          child: DropdownButton<int>(
            value: segments,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 (0.4)')),
              DropdownMenuItem(value: 10, child: Text('10 (0.2)')),
              DropdownMenuItem(value: 20, child: Text('20 (0.1)')),
            ],
            onChanged: (v) => onSegmentsChanged(v!),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
          ),
        ),

      if (colorMode == HeatmapColorMode.discrete)
        const SizedBox(width: 16),

      // Верхний треугольник
      _ControlItem(
        label: 'Верхний треугольник',
        child: Switch(
          value: triangleMode,
          onChanged: onTriangleModeChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      const SizedBox(width: 16),

      // Кластеризация
      _ControlItem(
        label: 'Кластеризация',
        child: Switch(
          value: clusterEnabled,
          onChanged: onClusterEnabledChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ];
  }
}

/// {@template control_item}
/// Внутренний виджет для отображения элемента управления с подписью
/// 
/// Содержит:
/// - Текстовую подпись сверху
/// - Дочерний элемент управления (Dropdown, Switch и т.д.)
/// {@endtemplate}
class _ControlItem extends StatelessWidget {
  /// Текст подписи
  final String label;

  /// Дочерний элемент управления
  final Widget child;

  /// {@macro control_item}
  const _ControlItem({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}