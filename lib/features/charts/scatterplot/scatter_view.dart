// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// import '../../../core/dataset/dataset.dart';
// import 'scatter_state.dart';

// class HistogramView extends StatelessWidget {

//   final Dataset dataset;
//   final ScatterState state;

//   const HistogramView({
//     super.key,
//     required this.dataset,
//     required this.state,
//   });

//   @override
//   Widget build(BuildContext context) {

//     if (state.firstColumnName == null || state.secondColumnName == null) {
//       return const Center(
//         child: Text("Выберите колонки"),
//       );
//     }

//     final firstColumn = dataset.numeric(state.firstColumnName!);
//     final secondColumn = dataset.numeric(state.secondColumnName!);

//     final v1 = firstColumn.data
//         .whereType<double>()
//         .toList();

//     final v2 = secondColumn.data
//         .whereType<double>()
//         .toList();

//     if (v1.isEmpty) {
//       return const Center(
//         child: Text("Нет данных для первой колонки"),
//       );
//     }

//     if (v2.isEmpty){
//       return const Center(
//         child: Text("Нет данных для второй колонки"),
//       );
//     }



//     return SfCartesianChart(
//       tooltipBehavior: TooltipBehavior(enable: true, duration: 2000, header: column.name, activationMode: ActivationMode.singleTap),
//       primaryXAxis: NumericAxis(),
//       primaryYAxis: NumericAxis(),
//       series: <ScatterSeries<double, double>>[
//         ScatterSeries<double, double>(
//           dataSource: values,
//           xValueMapper: (v, _) => ,
//           yValueMapper: (v, _) => v,
//           binInterval: interval,
//           enableTooltip: true,
//         ),
//       ],
//     );
//   }
// }