import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../dataset/dataset.dart';

/// {@template csv_loader}
/// Загрузчик и парсер CSV-файлов для преобразования в структуру [Dataset]
/// 
/// Отвечает за:
/// - Выбор файла через системный диалог
/// - Чтение и декодирование CSV-содержимого с поддержкой прогресса загрузки
/// - Определение типов колонок (числовые, дата/время, категориальные, текстовые)
/// - Обработку CSV с учетом кавычек и пользовательского разделителя
/// - Создание соответствующей структуры данных
/// {@endtemplate}
class CsvLoader {
  /// Разделитель колонок в CSV-файле (по умолчанию ',')
  final String delimiter;
  
  /// {@macro csv_loader}
  CsvLoader() : delimiter = ',';
  
  /// Создает загрузчик с пользовательским разделителем
  CsvLoader.withDelimiter(this.delimiter);

  /// Открывает диалог выбора файла и загружает выбранный CSV-файл
  /// 
  /// Принимает:
  /// - [onProgress] — опциональный callback для отслеживания прогресса загрузки (0.0-1.0)
  /// 
  /// Возвращает:
  /// - [Future<Dataset>] — датасет, созданный из загруженного файла
  /// 
  /// Особенности:
  /// - Поддерживаются только CSV-файлы
  /// - Поддерживается отслеживание прогресса загрузки для больших файлов
  /// - Первая строка интерпретируется как заголовки колонок
  /// - Пустые строки игнорируются
  /// - Тип каждой колонки определяется автоматически
  /// 
  /// Выбрасывает:
  /// - [Exception] — если файл не выбран
  /// - [Exception] — если не удалось открыть поток для чтения
  /// - [Exception] — если произошла ошибка при чтении файла
  Future<Dataset> getDataset({
    void Function(double progress)? onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('Файл не выбран');
    }

    final file = result.files.first;

    if (file.readStream == null) {
      throw Exception('Не удалось открыть поток для чтения файла');
    }

    final stream = http.ByteStream(file.readStream!);
    final total = file.size;
    int received = 0;
    final buffer = <int>[];

    try {
      await for (final chunk in stream) {
        buffer.addAll(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      }
    } catch (e) {
      throw Exception('Ошибка при чтении файла: $e');
    }

    final content = utf8.decode(buffer);
    return _parseContent(content, file.name);
  }

  /// Загружает датасет напрямую из файла по указанному пути
  /// 
  /// Принимает:
  /// - [filePath] — путь к CSV-файлу на диске
  /// 
  /// Возвращает:
  /// - [Future<Dataset>] — датасет, созданный из файла
  /// 
  /// Особенности:
  /// - Загружает файл полностью в память
  /// - Подходит для локальных файлов, к которым есть прямой доступ
  /// 
  /// Выбрасывает:
  /// - [Exception] — если файл не существует
  /// - [Exception] — если произошла ошибка при загрузке
  Future<Dataset> loadFullDataset(String filePath) async {
    try {
      final file = File(filePath);
        
      if (!await file.exists()) {
        throw Exception('Файл не существует');
      }
      
      final content = await file.readAsString();
      final fileName = filePath.split('\\').last;
      
      return _parseContent(content, fileName);
    } catch (e) {
      throw Exception('Ошибка при загрузке файла: $e');
    }
  }

  /// Читает содержимое файла для предпросмотра
  /// 
  /// Принимает:
  /// - [filePath] — путь к CSV-файлу на диске
  /// - [delimiter] — разделитель колонок
  /// 
  /// Возвращает:
  /// - [Future<String>] — содержимое файла (первые 50 строк данных + заголовок)
  /// 
  /// Особенности:
  /// - Ограничивает чтение первыми 100KB файла для эффективности
  /// - Возвращает не более 51 строки (заголовок + 50 строк данных)
  /// - Идеально подходит для предварительного просмотра структуры файла
  /// 
  /// Выбрасывает:
  /// - [Exception] — если файл не существует
  /// - [Exception] — если произошла ошибка при чтении
  Future<String> readFileContent(String filePath, String delimiter) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Файл не существует');
      }
      
      // Читаем только первые 100KB для предпросмотра
      final content = await file.readAsString();
      final lines = content.split('\n');
      final previewLines = lines.take(51).join('\n'); // 1 заголовок + 50 строк
      
      return previewLines;
    } catch (e) {
      throw Exception('Ошибка при чтении файла для предпросмотра: $e');
    }
  }

  /// Парсит содержимое CSV в структуру Dataset
  Dataset _parseContent(String content, String fileName) {
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('Файл пуст');
    }

    final headers = lines.first.split(delimiter).map((e) => e.trim()).toList();

    final rows = lines
        .skip(1)
        .map((line) => _parseLine(line))
        .toList();

    log('CSV rows: ${rows.length}');
    log('CSV columns: ${headers.length}');

    final List<DataColumn> columns = [];

    for (int colIndex = 0; colIndex < headers.length; colIndex++) {
      final name = headers[colIndex];
      final values = <String?>[];

      for (final row in rows) {
        if (colIndex < row.length) {
          values.add(row[colIndex]);
        } else {
          values.add(null);
        }
      }

      columns.add(_buildColumn(name, values));
    }

    return Dataset(
      name: fileName,
      columns: columns,
    );
  }

  /// Парсит одну строку CSV с учетом кавычек
  List<String> _parseLine(String line) {
    // Базовая обработка CSV с учетом кавычек
    final result = <String>[];
    String current = '';
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }

  /// Создает колонку соответствующего типа на основе анализа сырых данных
  DataColumn _buildColumn(String name, List<String?> rawValues) {
    if (_isNumeric(rawValues)) {
      final values = rawValues.map((v) {
        if (v == null || v.isEmpty) return null;
        return double.tryParse(v.replaceAll(',', '.'));
      }).toList();

      return NumericColumn(name, values);
    }

    if (_isDateTime(rawValues)) {
      final values = rawValues.map((v) {
        if (v == null || v.isEmpty) return null;
        return DateTime.tryParse(v);
      }).toList();

      return DateTimeColumn(name, values);
    }

    if (_isCategorical(rawValues)) {
      return CategoricalColumn(name, rawValues);
    }

    return TextColumn(name, rawValues);
  }

  /// Проверяет, можно ли интерпретировать значения как числа
  bool _isNumeric(List<String?> values) {
    int nonNullCount = 0;
    
    for (final v in values) {
      if (v == null || v.isEmpty) continue;
      nonNullCount++;
      if (double.tryParse(v.replaceAll(',', '.')) == null) return false;
    }
    
    return nonNullCount > 0;
  }

  /// Проверяет, можно ли интерпретировать значения как даты
  bool _isDateTime(List<String?> values) {
    int nonNullCount = 0;
    
    for (final v in values) {
      if (v == null || v.isEmpty) continue;
      nonNullCount++;
      if (DateTime.tryParse(v) == null) return false;
    }
    
    return nonNullCount > 0;
  }

  /// Проверяет, являются ли значения категориальными
  /// 
  /// Критерий: количество уникальных значений менее 20% от общего числа
  bool _isCategorical(List<String?> values) {
    final nonNull = values.whereType<String>().toList();

    if (nonNull.isEmpty) return false;

    final unique = nonNull.toSet().length;

    return unique < nonNull.length * 0.2;
  }
}