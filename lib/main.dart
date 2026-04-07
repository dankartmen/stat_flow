import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stat_flow/features/charts/register_charts.dart';
import 'package:stat_flow/features/screens/main_screen.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

  void main() {
    registerCharts();
    runApp(const ProviderScope(child: MyApp()));
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        showPerformanceOverlay: kDebugMode,
        title: 'StatFlow',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate
        ],
        supportedLocales: const [
          const Locale('ru', 'RU'),
        ],
        home: const MainScreen(),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),

        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
        ),
      );
    }
  }

  