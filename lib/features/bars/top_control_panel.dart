import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stat_flow/features/charts/chart_controls_builder.dart';
import 'package:stat_flow/features/charts/floating_chart/floating_chart_data.dart';
/// {@template top_control_panel}
/// Верхняя панель управления для настройки отображения графиков
/// 
/// Отображает контекстные элементы управления в зависимости от типа графика:
/// - Для тепловой карты: выбор палитры, режима раскраски, количества сегментов,
///   отображение верхнего треугольника, включение кластеризации
/// - Для гистограммы: выбор колонки, количества бинов
/// - Для ящика с усами: выбор колонки
/// 
/// Панель имеет фиксированную высоту 80 пикселей и адаптируется под разные типы графиков.
/// {@endtemplate}
class TopControlPanel extends ConsumerWidget {

  /// Данные текущего графика для отображения и управления 
  final FloatingChartData chart;

  /// Коллбек для уведомления об изменениях в настройках графика, чтобы обновить отображение
  final VoidCallback onChanged;

  /// {@macro top_control_panel}
  const TopControlPanel({
    super.key,
    required this.chart,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  children: ChartControlsBuilder.build(
                    chart,
                    onChanged,
                    ref
                  ),
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
          Text(
            chart.type.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  
}