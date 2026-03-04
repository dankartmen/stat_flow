import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:stat_flow/features/charts/chart_screenshot_wrapper.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_view.dart';
import 'package:stat_flow/features/charts/heatmap/model/correlation_matrix.dart';
import 'package:stat_flow/features/dataset/dataset.dart';
import 'package:stat_flow/features/statistics/statistic_calculator.dart';
import 'package:stat_flow/features/statistics/statistic_result.dart';
import 'package:stat_flow/features/table/pluto_grid_converter.dart';
import 'features/charts/heatmap/widgets/heatmap_section.dart';
import 'features/file_import/file_import.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV File Loader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ru', 'RU'),
      ],
      home: const FileLoaderScreen(),
    );
  }
}

/// Главный экран приложения для загрузки и отображения файлов.
class FileLoaderScreen extends StatefulWidget {
  const FileLoaderScreen({super.key});

  @override
  State<FileLoaderScreen> createState() => _FileLoaderScreenState();
}

class _FileLoaderScreenState extends State<FileLoaderScreen> {
  /// Сервис для загрузки файлов
  final FileLoader _fileLoader = FileLoader();

  /// Флаг состояния загрузки
  bool _isLoading = false;

  /// Флаг для показа таблицы
  bool _isTableVisible = false;
  
  /// Данные для таблицы
  PlutoGridData? _plutoGridData; 

  /// Статистические данные
  StatisticResult? _statisticResult;

  /// Датасет
  Dataset? _dataset;
  /// Состояние для показа статистики
  bool _showStatistics = false;
  
  /// Состояние для плавающего окна
  Offset _windowPosition = const Offset(80, 80);
  Size _windowSize = const Size(720, 520);
  final Size _minSize = const Size(380, 280);

  /// Загружает файл и обновляет состояние
  /// 
  /// Показывает индикатор загрузки, обрабатывает ошибки
  /// и конвертирует данные в формат PlutoGrid.
  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _showStatistics = false;
    });

    try {
      // Загружаем датасет
      final loadedDataset = await _fileLoader.getDataset();
      
      // Конвертируем в формат PlutoGridData
      final converter = PlutoGridConverter();
      final gridData = converter.convert(loadedDataset);

      final calculator = StatisticCalculator();
      final numColumn = loadedDataset.columns
        .where((column) => column.type == ColumnType.numeric).toList();
      final values = numColumn.first.values.map((v) => v as num?).toList();
      final result = calculator.calculate(values);
      debugPrint(result.toString());
      setState(() {
        _isLoading = false;
        _isTableVisible = true;
        _showStatistics = true;
        _dataset = loadedDataset;
        _plutoGridData = gridData;
        _statisticResult = result;
        _windowPosition = const Offset(80, 80);
        _windowSize = const Size(720, 520);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(e);
    }
  }

  /// Показывает сообщение об ошибке в SnackBar
  void _showErrorSnackBar(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка загрузки: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Строит экран приветствия с кнопкой загрузки.
  ///
  /// Отображается, когда данные еще не загружены.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 80,
              color: Colors.blue.shade300,
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Загрузите CSV файл',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Выберите CSV файл для загрузки и анализа данных',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Выбрать файл',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит плавающее окно с таблицей данных.
  ///
  /// Окно можно:
  /// - Перетаскивать за заголовок
  /// - Закрыть кнопкой закрытия
  /// - Изменять размер через отдельный хендлер
  Widget _buildFloatingTable() {
    return Positioned(
      left: _windowPosition.dx,
      top: _windowPosition.dy,
      width: _windowSize.width,
      height: _windowSize.height,
      child: Material(
        elevation: 8, // Тень для эффекта "парения"
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Заголовок + перетаскивание
            GestureDetector(
              // Перетаскивание за заголовок
              onPanUpdate: (details) {
                setState(() {
                  _windowPosition += details.delta; // Обновляем позицию  
                });
              },
              child: Container(
                color: Colors.blueGrey[800],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Таблица данных",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isTableVisible = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Таблица
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PlutoGrid(
                  columns: _plutoGridData!.columns,
                  rows: _plutoGridData!.rows,
                  columnGroups: _plutoGridData!.columnGroups,
                  onLoaded: (event) {},
                  configuration: const PlutoGridConfiguration(
                    columnSize: PlutoGridColumnSizeConfig(
                      autoSizeMode: PlutoAutoSizeMode.scale, // Автомасштабирование колонок
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит хендлер для изменения размера плавающего окна.
  ///
  /// Расположен в правом нижнем углу окна и позволяет
  /// изменять размер с учетом минимальных ограничений.
  Widget _buildResizeHandle() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        // Изменение размера
        onPanUpdate: (details) {
          setState(() {
            double newWidth = _windowSize.width + details.delta.dx;
            double newHeight = _windowSize.height + details.delta.dy;

            // Ограничения минимального размера
            newWidth = newWidth.clamp(_minSize.width, double.infinity);
            newHeight = newHeight.clamp(_minSize.height, double.infinity);

            _windowSize = Size(newWidth, newHeight);
          });
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
            ),
          ),
          child: const Icon(
            Icons.open_in_full,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stat Flow — Загрузчик данных'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: _plutoGridData != null
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _plutoGridData = null;
                      _showStatistics = false;
                    });
                  },
                  tooltip: 'Загрузить другой файл',
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          // Основной контент
          _buildMainContent(),

          // Плавающее окно с таблицей
          if (_isTableVisible == true) ...[
            _buildFloatingTable(),
            _buildResizeHandle(),
          ],
        ],
      ),
      
      
      drawer: Drawer(
        width: 200,
        child: _buildDrawerContent(),
      ),
    );
  }

  /// Строит содержимое бокового меню (drawer).
  ///
  /// Содержит:
  /// - Заголовок с информацией о состоянии
  /// - Пункты навигации и управления
  /// - Информацию о программе
  Widget _buildDrawerContent() {
    return Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Stat Flow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _plutoGridData != null ? 'Данные загружены' : 'Нет данных',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Загрузить данные'),
                onTap: () {
                  Navigator.pop(context); // Закрываем drawer
                  _loadFile();
                },
              ),
              if (_plutoGridData != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Показать таблицу'),
                  subtitle: const Text('Плавающее окно'),
                  onTap: () {
                    if (_isTableVisible == true){
                      Navigator.pop(context);
                      // Фокус на таблицу (она уже видна)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Таблица уже открыта'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                    else{
                      setState(() => _isTableVisible = true);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.bar_chart,
                    color: _showStatistics ? Colors.blue : null,
                  ),
                  title: Text(
                    'Статистика',
                    style: TextStyle(
                      fontWeight: _showStatistics ? FontWeight.bold : null,
                      color: _showStatistics ? Colors.blue : null,
                    ),
                  ),
                  subtitle: const Text('Анализ числовых данных'),
                  trailing: _showStatistics
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _showStatistics = !_showStatistics;
                    });
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('О программе'),
                subtitle: const Text('Версия 1.0.0'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }


  /// Показывает диалог с информацией о программе.
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О программе Stat Flow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Версия: 1.0.0'),
            SizedBox(height: 8),
            Text(
              'Приложение для загрузки и анализа CSV файлов. '
              'Позволяет просматривать данные в плавающей таблице '
              'и рассчитывать статистические показатели.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Строит основное содержимое экрана в зависимости от состояния.
  ///
  /// Возможные состояния:
  /// - Загрузка: показывает индикатор прогресса
  /// - Нет данных: показывает пустое состояние с кнопкой загрузки
  /// - Данные загружены: показывает информацию и статистику
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_plutoGridData == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
      
                const SizedBox(height: 20),
      
                if (_showStatistics) ...[
                  HeatmapSection(
                    matrix: CorrelationMatrix.fromColumns(_dataset!.columns),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}