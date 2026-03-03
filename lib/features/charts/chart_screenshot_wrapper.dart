import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';

/// {@template chart_screenshot_wrapper}
/// Виджет-обёртка над графиком, позволяющая захватить его
/// как png изображение с помощью пакета screenshot
/// {@endtemplate}
class ChartScreenshotWrapper extends StatefulWidget{
  final Widget child;

  /// @{macro chart_screenshot_wrapper}
  const ChartScreenshotWrapper({
    super.key,
    required this.child
  });

  @override
  State<ChartScreenshotWrapper> createState() => _ChartScreenshotWrapperState();
}

class _ChartScreenshotWrapperState extends State<ChartScreenshotWrapper>{
  /// Контроллер для захвата изображения
  final ScreenshotController _controller = ScreenshotController();

  /// Захваченное изображение
  Uint8List? _capturedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screenshot(
        controller: _controller,
        child: Center(child: widget.child)),
    );
  }

}