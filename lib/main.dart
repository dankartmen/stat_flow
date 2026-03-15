import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stat_flow/features/charts/register_charts.dart';
import 'package:stat_flow/features/screens/main_screen.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';


  void main() {
    registerCharts();
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        showPerformanceOverlay: true,
        title: 'StatFlow',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate
        ],
        supportedLocales: [
          const Locale('ru', 'RU'),
        ],
        home: const MainScreen(),
      );
    }
  }

  