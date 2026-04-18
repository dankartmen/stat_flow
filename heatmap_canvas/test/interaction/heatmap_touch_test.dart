import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/src/model/heatmap_config.dart';
import 'package:heatmap_canvas/src/model/heatmap_data.dart';
import 'package:heatmap_canvas/src/model/touch_data.dart';
import 'package:heatmap_canvas/src/widgets/heatmap.dart';
import 'package:mockito/mockito.dart';



class MockTouchCallback extends Mock {
  void call(FlTouchEvent event, HeatmapTouchResponse? response);
}

void main() {
  testWidgets('Heatmap calls touchCallback on hover', (tester) async {
    bool called = false;
    final data = HeatmapData(
      rowLabels: ['R1'],
      columnLabels: ['C1'],
      values: [[1.0]],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Heatmap(
            data: data,
            config: HeatmapConfig(
              touchData: HeatmapTouchData(
                touchCallback: (event, response) => called = true,
                handleBuiltInTouches: false,
              ),
            ),
          ),
        ),
      ),
    );

    // Находим центр ячейки (примерно)
    final heatmapFinder = find.byType(Heatmap);
    final center = tester.getCenter(heatmapFinder);
    
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });


  testWidgets('Built-in tooltip shows on hover', (tester) async {
    final data = HeatmapData(
      rowLabels: ['R1'],
      columnLabels: ['C1', 'C2'],
      values: [[1.0, 2.0]],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: Heatmap(
              data: data,
              config: const HeatmapConfig(
                touchData: HeatmapTouchData(handleBuiltInTouches: true),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final heatmapFinder = find.byType(Heatmap);
    final center = tester.getCenter(heatmapFinder);
    
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(center);
    await tester.pumpAndSettle();

    // Тултип должен содержать текст
    expect(find.text('R1 × C1'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}