import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:stat_flow/features/table/pluto_grid_converter.dart';
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
      home: const FileLoaderScreen(),
    );
  }
}

class FileLoaderScreen extends StatefulWidget {
  const FileLoaderScreen({super.key});

  @override
  State<FileLoaderScreen> createState() => _FileLoaderScreenState();
}

class _FileLoaderScreenState extends State<FileLoaderScreen> {
  // Сервис для загрузки файлов
  final FileLoader _fileLoader = FileLoader();

  // Флаг состояния загрузки
  bool _isLoading = false;

  // Данные для таблицы
  PlutoGridData? _plutoGridData; 

  /// Загружает файл и обновляет состояние
  /// 
  /// Показывает индикатор загрузки, обрабатывает ошибки
  /// и конвертирует данные в формат PlutoGrid.
  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      /// Загружаем датасет
      final loadedDataset = await _fileLoader.getDataset();
      
      // Конвертируем в формат PlutoGridData
      final converter = PlutoGridConverter();
      final gridData = converter.convert(loadedDataset);
      
      setState(() {
        _isLoading = false;
        _plutoGridData = gridData;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
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

  /// Строит экран приветствия с кнопкой загрузки
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


  /// Строит таблицу с загруженными данными
  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PlutoGrid(
        columns: _plutoGridData!.columns,
        rows: _plutoGridData!.rows,
        columnGroups: _plutoGridData!.columnGroups,
        onLoaded: (PlutoGridOnLoadedEvent event) {
          // Сохраняем ссылку на stateManager если понадобится
          // final stateManager = event.stateManager;
        },
        configuration: const PlutoGridConfiguration(
          columnSize: PlutoGridColumnSizeConfig(
            autoSizeMode: PlutoAutoSizeMode.scale,
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
                    });
                  },
                  tooltip: 'Загрузить другой файл',
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  /// Выбирает, что отображать(загрузку, пустой экран или таблицу)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_plutoGridData != null) {
      return _buildTableView();
    } else {
      return _buildEmptyState();
    }
  }
}