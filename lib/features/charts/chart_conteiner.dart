import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ChartContainer extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? controls;

  const ChartContainer({
    super.key,
    required this.title,
    required this.child,
    this.controls,
  });

  @override
  State<ChartContainer> createState() => _ChartContainerState();
}

class _ChartContainerState extends State<ChartContainer> {

  final GlobalKey _chartKey = GlobalKey();

  Future<void> _exportPng() async {

    final boundary = _chartKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);

    final byteData =
        await image.toByteData(format: ImageByteFormat.png);

    final pngBytes = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png");

    await file.writeAsBytes(pngBytes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved: ${file.path}")),
    );
  }

  void _openFullscreen() {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Center(child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: widget.child,
          )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 4,
      child: Column(
        children: [
          _buildHeader(),

          if (widget.controls != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: widget.controls!,
          ),
          
          /// CHART
          Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: _chartKey,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(){
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),

      child: Row(
        children: [

          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          IconButton(
            tooltip: "Export PNG",
            icon: const Icon(Icons.download),
            onPressed: _exportPng,
          ),

          IconButton(
            tooltip: "Fullscreen",
            icon: const Icon(Icons.open_in_full),
            onPressed: _openFullscreen,
          ),
        ],
      ),
    );
  }
}