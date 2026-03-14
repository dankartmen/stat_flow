import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stat_flow/core/loader/csv_loader.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../grid/preview_data_source.dart';

/// {@template table_preview_screen}
/// Экран предварительного просмотра CSV-файла перед загрузкой
/// 
/// Отвечает за:
/// - Выбор CSV-файла через системный диалог
/// - Предварительный просмотр структуры данных (первые 50 строк)
/// - Выбор разделителя колонок (, ; | \t)
/// - Отображение данных в интерактивной таблице с возможностью сортировки и фильтрации
/// - Полную загрузку датасета после подтверждения пользователя
/// 
/// Возвращает загруженный [Dataset] при успешной загрузке.
/// {@endtemplate}
class TablePreviewScreen extends StatefulWidget {
  /// {@macro table_preview_screen}
  const TablePreviewScreen({super.key});

  @override
  State<TablePreviewScreen> createState() => _TablePreviewScreenState();
}

class _TablePreviewScreenState extends State<TablePreviewScreen> {
  /// Путь к выбранному файлу
  String? _filePath;

  /// Заголовки колонок
  List<String> _headers = [];

  /// Строки данных для предпросмотра
  List<List<String>> _rows = [];

  /// Текущий разделитель колонок
  String _delimiter = ',';

  /// Флаг загрузки
  bool _isLoading = false;

  /// Источник данных для таблицы
  PreviewDataSource? _dataSource;

  /// Список распространенных разделителей для выбора
  final List<String> _commonDelimiters = [',', ';', '\t', '|'];

  @override
  void initState() {
    super.initState();
    _pickFile();
  }

  /// Открывает диалог выбора файла
  /// 
  /// Особенности:
  /// - Поддерживаются только CSV-файлы
  /// - При отмене выбора возвращает на предыдущий экран
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    setState(() {
      _filePath = result.files.single.path;
      _isLoading = true;
    });

    await _loadPreview();
  }

  /// Загружает предварительный просмотр файла
  /// 
  /// Особенности:
  /// - Загружает только первые 50 строк + заголовок
  /// - Автоматически обновляет таблицу при смене разделителя
  /// - Показывает ошибки при неудачной загрузке
  Future<void> _loadPreview() async {
    if (_filePath == null) return;

    try {
      final loader = CsvLoader.withDelimiter(_delimiter);
      final content = await loader.readFileContent(_filePath!, _delimiter);

      final lines = content
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.isNotEmpty) {
        final headers = lines.first.split(_delimiter).map((e) => e.trim()).toList();
        final rows = lines
            .skip(1)
            .take(50)
            .map((line) => line.split(_delimiter).map((e) => e.trim()).toList())
            .toList();

        setState(() {
          _headers = headers;
          _rows = rows;
          _dataSource = PreviewDataSource(headers, rows);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Файл не содержит данных');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка загрузки файла: $e');
    }
  }

  /// Отображает сообщение об ошибке
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Загружает полный датасет
  /// 
  /// Возвращает:
  /// - [Dataset] — полный загруженный датасет на предыдущий экран
  Future<void> _loadFullDataset() async {
    setState(() => _isLoading = true);

    try {
      final loader = CsvLoader.withDelimiter(_delimiter);
      final dataset = await loader.loadFullDataset(_filePath!);

      if (mounted) {
        Navigator.pop(context, dataset);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка полной загрузки: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предварительный просмотр данных'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка данных...'),
                ],
              ),
            )
          : Column(
              children: [
                // Панель выбора разделителя
                _buildDelimiterPanel(),

                // Таблица предпросмотра
                Expanded(
                  child: _headers.isEmpty || _dataSource == null
                      ? _buildEmptyState()
                      : SfDataGrid(
                          source: _dataSource!,
                          columns: _headers.map((header) {
                            return GridColumn(
                              columnName: header,
                              label: Container(
                                padding: const EdgeInsets.all(8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  header,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          columnWidthMode: ColumnWidthMode.auto,
                          gridLinesVisibility: GridLinesVisibility.both,
                          headerGridLinesVisibility: GridLinesVisibility.both,
                          allowSorting: true,
                          allowFiltering: true,
                          isScrollbarAlwaysShown: true,
                          frozenColumnsCount: 0,
                          rowHeight: 40,
                          headerRowHeight: 50,
                        ),
                ),

                // Кнопки действий
                _buildActionButtons(),
              ],
            ),
    );
  }

  /// Строит панель выбора разделителя
  Widget _buildDelimiterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Text(
            'Разделитель:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          ..._commonDelimiters.map((delimiter) {
            final display = delimiter == '\t'
                ? 'Tab'
                : delimiter == '|'
                    ? 'Pipe'
                    : delimiter;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(display),
                selected: _delimiter == delimiter,
                onSelected: (_) {
                  setState(() {
                    _delimiter = delimiter;
                    _isLoading = true;
                  });
                  _loadPreview();
                },
              ),
            );
          }),
          const Spacer(),
          if (_rows.isNotEmpty)
            Text('Показано ${_rows.length} из ${_rows.length}+ строк'),
        ],
      ),
    );
  }

  /// Строит состояние пустой таблицы
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_rows,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет данных для отображения',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Строит панель с кнопками действий
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _headers.isNotEmpty ? _loadFullDataset : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            child: const Text('Загрузить полный датасет'),
          ),
        ],
      ),
    );
  }
}