import 'package:flutter/material.dart';

/// {@template fullscreen_chart}
/// Виджет для отображения графика в полноэкранном режиме
/// 
/// Предоставляет:
/// - AppBar с названием графика и кнопками управления
/// - Кнопку закрытия (возврат к плавающему режиму)
/// - Кнопку экспорта (заглушка для будущей функциональности)
/// - Центрированное содержимое графика с отступами
/// 
/// Используется при нажатии на кнопку полноэкранного режима в [FloatingChart].
/// {@endtemplate}
class FullscreenChart extends StatelessWidget {
  /// Заголовок графика (отображается в AppBar)
  final String title;

  /// Дочерний виджет (содержимое графика)
  final Widget child;

  /// {@macro fullscreen_chart}
  const FullscreenChart({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}