import 'package:flutter/material.dart';

import '../charts/floating_chart/floating_chart_container.dart';

/// {@template canvas_workspace}
/// Холст для размещения плавающих графиков с ограничениями по размерам
/// 
/// Предоставляет контейнер, который:
/// - Адаптируется к размерам родительского виджета через [LayoutBuilder]
/// - Ограничивает область отображения через [ClipRect]
/// - Передает границы области дочерним [FloatingChart] виджетам
/// 
/// Используется в главном экране для создания рабочей области с плавающими окнами.
/// {@endtemplate}
class CanvasWorkspace extends StatelessWidget {
  /// Дочерние виджеты для отображения на холсте
  final List<Widget> children;

  /// {@macro canvas_workspace}
  const CanvasWorkspace({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return SizedBox(
          width: bounds.width,
          height: bounds.height,
          child: ClipRect(
            child: Stack(
              children: children.map((child) {
                // Передаем границы только FloatingChart виджетам
                if (child is FloatingChart) {
                  return child.withBounds(bounds);
                }
                return child;
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}