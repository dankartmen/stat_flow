import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stat_flow/features/charts/register_charts.dart';
import 'package:stat_flow/features/screens/main_screen.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/theme_provider.dart';

  void main() {
    registerCharts();
    runApp(const ProviderScope(child: MyApp()));
  }

  class MyApp extends ConsumerWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final theme = ref.watch(currentThemeProvider);

      return MaterialApp(
        showPerformanceOverlay: false,
        title: 'StatFlow',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
        ],
        home: const MainScreen(),
        theme: theme,
      );
    }
  }