import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heatmap_canvas/src/model/heatmap_data.dart';
import 'package:heatmap_canvas/src/widgets/heatmap.dart' show Heatmap;

void main() {

  testWidgets('Full flow: change data with animation', (tester) async {
    final data1 = HeatmapData(
      rowLabels: ['A'],
      columnLabels: ['B'],
      values: [[0.0]],
    );
    final data2 = HeatmapData(
      rowLabels: ['A'],
      columnLabels: ['B'],
      values: [[100.0]],
    );

    await tester.pumpWidget(MaterialApp(home: Heatmap(data: data1)));
    expect(find.text('0'), findsOneWidget);

    // Переключаем данные
    await tester.pumpWidget(MaterialApp(home: Heatmap(data: data2)));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // Должен появиться текст '100'
    expect(find.text('100'), findsOneWidget);
  });
}