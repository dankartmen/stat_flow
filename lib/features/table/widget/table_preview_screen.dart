import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stat_flow/core/loader/csv_loader.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../core/dataset/dataset.dart';
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

  /// Кэшированные колонки для SfDataGrid 
  List<GridColumn> _gridColumns = [];

  /// Список распространенных разделителей для выбора
  final List<String> _commonDelimiters = [',', ';', '\t', '|'];

  /// Прогресс полной загрузки датасета
  double _fullLoadProgress = 0.0;

  /// Флаг полной загрузки датасета
  bool _isFullLoading = false;

  /// Статус полной загрузки датасета для отображения пользователю
  String _fullLoadStatus = '';

  @override
  void initState() {
    super.initState();
    _pickFile();
  }

  /// Открывает диалог выбора файла и загружает предварительный просмотр при выборе
  /// Если пользователь отменяет выбор, возвращается на предыдущий экран. При выборе файла начинается загрузка первых строк для предпросмотра.
  /// Использует пакет file_picker для открытия системного диалога выбора файла и получения пути к выбранному файлу. После получения пути вызывается метод _loadPreview для загрузки данных.
  /// 
  /// Особенности:
  /// - Поддерживает только файлы с расширением .csv
  /// - Обрабатывает отмену выбора файла и возвращается на предыдущий экран без ошибок
  /// - При выборе файла сразу начинает загрузку данных для предпросмотра
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
      return;
    }
    _filePath = result.files.single.path;
    await _loadPreview();
  }

  /// Загружает первые строки CSV-файла для предварительного просмотра
  /// Читает содержимое файла, разбивает его на строки и колонки, и формирует данные для отображения в таблице. Обновляет состояние с заголовками, строками и источником данных для таблицы.
  ///
  /// Особенности:
  /// - Читает только первые 50 строк после заголовков для быстрого отображения предпросмотра
  /// - Поддерживает динамическое изменение разделителя и обновляет предпросмотр в реальном времени
  /// - Обрабатывает ошибки при чтении файла и отображает сообщение пользователю
  Future<void> _loadPreview() async {
    if (_filePath == null) return;
    setState(() => _isLoading = true);
    try {
      final loader = CsvLoader.withDelimiter(_delimiter);
      // Читаем только первые строки (без полного парсинга)
      final content = await loader.readFileContent(_filePath!, _delimiter);
      if (!mounted) return;
      
      final lines = content
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) throw Exception('Файл пуст');
      
      final headers = lines.first.split(_delimiter).map((e) => e.trim()).toList();
      final rows = lines.skip(1).take(50).map((line) {
        return line.split(_delimiter).map((e) => e.trim()).toList();
      }).toList();
      
      setState(() {
        _headers = headers;
        _rows = rows;
        _dataSource = PreviewDataSource(headers, rows);
        _gridColumns = headers.map((header) => GridColumn(
          columnName: header,
          label: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            child: Text(header, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка загрузки предпросмотра: $e');
    }
  }

  /// Отображает сообщение об ошибке
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Загружает полный датасет из CSV-файла и возвращает его на предыдущий экран
  /// Читает весь файл, парсит его в формат Dataset и возвращает результат на предыдущий экран. Во время загрузки отображает прогресс и статус загрузки. Обрабатывает ошибки и отображает сообщение пользователю при неудачной загрузке.
  /// Особенности:
  /// - Загружает весь файл, а не только первые строки, для полноценного отображения в основной таблице
  /// - Использует прогресс-бар для отображения статуса загрузки, особенно при обработке больших файлов
  /// - Обрабатывает ошибки при чтении и парсинге файла, информируя пользователя о проблемах с загрузкой
  Future<void> _loadFullDataset() async {
    if (_filePath == null) return;
    setState(() {
      _isFullLoading = true;
      _fullLoadProgress = 0.0;
      _fullLoadStatus = 'Начинаем загрузку...';
    });

    try {
      final loader = CsvLoader.withDelimiter(_delimiter);
      final dataset = await loader.loadFullDataset(
        _filePath!,
        onProgress: (progress,status) {
          if (mounted) {
            setState((){
              _fullLoadProgress = progress ?? 0.5;
              _fullLoadStatus = status;
            });
          }
        },
      );
      if (mounted) Navigator.pop(context, dataset);
    } catch (e) {
      if (mounted) {
        setState(() => _isFullLoading = false);
        debugPrint('$e');
        _showError('Ошибка полной загрузки: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предварительный просмотр данных'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _DelimiterPanel(
                  delimiter: _delimiter,
                  commonDelimiters: _commonDelimiters,
                  rowsCount: _rows.length,
                  onDelimiterChanged: (newDelimiter) {
                    setState(() => _delimiter = newDelimiter);
                    _loadPreview();
                  },
                ),
                Expanded(
                  child: _headers.isEmpty
                      ? const _EmptyTableState()
                      : SfDataGrid(
                          source: _dataSource!,
                          columns: _gridColumns,
                          columnWidthMode: ColumnWidthMode.auto,
                          gridLinesVisibility: GridLinesVisibility.both,
                          headerGridLinesVisibility: GridLinesVisibility.both,
                          allowSorting: true,
                          allowFiltering: true,
                          isScrollbarAlwaysShown: true,
                          rowHeight: 40,
                          headerRowHeight: 50,
                        ),
                ),
                _isFullLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fullLoadStatus),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: _fullLoadProgress < 1.0 && _fullLoadStatus.contains('Обработка')
                            ? null // indeterminate при обработке
                            : _fullLoadProgress,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_fullLoadProgress < 1.0 && !_fullLoadStatus.contains('Обработка'))
                        Text('${(_fullLoadProgress * 100).toStringAsFixed(0)}%'),
                    ],
                  )
                : _ActionButtons(
                    onCancel: () => Navigator.pop(context),
                    onLoad: _headers.isNotEmpty ? _loadFullDataset : null,
                  ),
              ],
            ),
    );
  }
}

/// {@template empty_table_state}
/// Показ состояния при отсутствии данных для отображения в таблице
/// Отображает:
/// - Иконку таблицы с серым цветом
/// - Сообщение "Нет данных для отображения" с серым цветом
/// Используется в случае, если файл не содержит данных или произошла ошибка при загрузке
/// {@endtemplate}
class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_rows, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Нет данных для отображения',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// {@template delimiter_panel}
/// Панель выбора разделителя колонок для CSV-файла
/// Отображается в верхней части экрана предпросмотра таблицы
/// Содержит:
/// - Метку "Разделитель:"
/// - Набор кнопок для выбора распространенных разделителей (",", ";", "\t", "|")
/// - Информацию о количестве отображаемых строк в предпросмотре
/// Позволяет пользователю быстро переключаться между различными разделителями и видеть изменения в структуре данных в реальном времени
/// {@endtemplate}
class _DelimiterPanel extends StatelessWidget {
  /// Текущий выбранный разделитель
  final String delimiter;
  /// Список распространенных разделителей для отображения в виде кнопок
  final List<String> commonDelimiters;
  /// Количество строк, отображаемых в предпросмотре
  final int rowsCount;

  /// Коллбек при изменении разделителя, который обновляет предпросмотр таблицы
  final ValueChanged<String> onDelimiterChanged;

  const _DelimiterPanel({
    required this.delimiter,
    required this.commonDelimiters,
    required this.rowsCount,
    required this.onDelimiterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Text('Разделитель:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ...commonDelimiters.map((delim) {
            final display = delim == '\t' ? 'Tab' : delim == '|' ? 'Pipe' : delim;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(display),
                selected: delimiter == delim,
                onSelected: (_) => onDelimiterChanged(delim),
              ),
            );
          }),
          const Spacer(),
          if (rowsCount > 0)
            Text('Показано $rowsCount из $rowsCount+ строк'),
        ],
      ),
    );
  }
}

/// {@template action_buttons}
/// Панель кнопок действий для экрана предпросмотра таблицы
/// Расположена в нижней части экрана и обеспечивает основные действия пользователя:
/// - "Отмена" - возвращает пользователя на предыдущий экран без загрузки данных
/// - "Загрузить полный датасет" - инициирует загрузку полного датасета и возвращает его на предыдущий экран при успешной загрузке
/// Кнопка "Загрузить полный датасет" активна только при наличии данных в предпросмотре, предотвращая попытки загрузки пустого датасета
/// {@endtemplate}
class _ActionButtons extends StatelessWidget {
  /// Коллбек для отмены загрузки и возврата на предыдущий экран
  final VoidCallback onCancel;
  /// Коллбек для загрузки полного датасета и возврата его на предыдущий экран
  final VoidCallback? onLoad;

  const _ActionButtons({required this.onCancel, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Загрузить полный датасет'),
          ),
        ],
      ),
    );
  }
}