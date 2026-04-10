import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  
    final resultMap = await compute(_parseCsvInIsolate, (content, file.name, delimiter));
    return _buildDatasetFromResult(resultMap, file.name);
  }

  /// Загружает датасет напрямую из файла по указанному пути
  /// 
  /// Принимает:
  /// - [filePath] — путь к CSV-файлу на диске
  /// - [onProgress] — опциональный callback для отслеживания прогресса загрузки (0.0-1.0)
  ///
  /// Возвращает:
  /// - [Future<Dataset>] — датасет, созданный из загруженного файла
  /// 
  /// Особенности:
  /// - Чтение файла происходит по частям с поддержкой прогресса для больших файлов
  /// - Первая строка интерпретируется как заголовки колонок
  /// - Пустые строки игнорируются
  /// - Тип каждой колонки определяется автоматически
  /// 
  /// Выбрасывает:
  /// - [Exception] — если файл не существует
  /// - [Exception] — если произошла ошибка при чтении файла
  /// - [Exception] — если произошла ошибка при обработке данных
  /// - [Exception] — если файл пустой или не содержит данных
  /// - [Exception] — если произошла ошибка при определении типов данных
  Future<Dataset> loadFullDataset(
    String filePath, {
    void Function(double? progress, String status)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Файл не существует');
    }
    final size = await file.length();
    final raf = await file.open();
    final buffer = <int>[];
    int received = 0;
    const chunkSize = 65536;
    
    while (received < size) {
      final bytes = await raf.read(chunkSize);
      if (bytes.isEmpty) break;
      buffer.addAll(bytes);
      received += bytes.length;
      if (onProgress != null && size > 0) {
        final readProgress = received / size * 0.5;
        onProgress(readProgress, 'Чтение файла...');
      }
    }
    await raf.close();

    // После чтения файла, начинаем обработку данных (парсинг и определение типов)
    if (onProgress != null) {
      onProgress(null, 'Обработка данных...');
    }

    final content = utf8.decode(buffer);
    final fileName = filePath.split(Platform.pathSeparator).last;
    
    final resultMap = await compute(_parseCsvInIsolate, (content, fileName, delimiter));

    if (onProgress != null) {
      onProgress(1.0, 'Загрузка завершена');
    }

    return _buildDatasetFromResult(resultMap, fileName);
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


  /// Статическая функция для парсинга CSV в isolate
  /// Принимает:
  /// - [content] — содержимое CSV-файла в виде строки
  /// - [fileName] — имя файла для использования в названии датасета
  /// - [delimiter] — разделитель колонок
  /// Возвращает:
  /// - [Map<String, dynamic>] — результат парсинга с информацией о колонках и типах данных 
  /// Особенности:
  /// - Парсинг выполняется в isolate для предотвращения блокировки UI при обработке больших файлов
  /// - Поддерживает корректную обработку кавычек и пользовательского разделителя
  /// - Определяет тип каждой колонки на основе первых 1000 строк данных для оптимизации производительности
  static Map<String, dynamic> _parseCsvInIsolate((String content, String fileName, String delimiter) args) {
    final (content, fileName, delimiter) = args;
    final lines = content.split('\n');
    if (lines.isEmpty) throw Exception('Файл пуст');
    
    final headers = lines.first.split(delimiter).map((e) => e.trim()).toList();
    final int totalLines = lines.length;
    
    // Инициализируем списки колонок заранее, чтобы заполнять их по мере чтения строк
    final columnsData = <String, List<String?>>{};
    for (final header in headers) {
      columnsData[header] = List.filled(totalLines - 1, null);
    }
    
    // Заполняем данные
    for (int i = 1; i < totalLines; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final row = _parseLineStatic(line, delimiter);
      for (int j = 0; j < headers.length; j++) {
        final value = j < row.length ? row[j] : null;
        columnsData[headers[j]]![i - 1] = value;
      }
    }
    
    // Определяем типы только по первым 1000 строкам
    const sampleSize = 1000;
    final sampleLimit = min(sampleSize, totalLines - 1);
    final types = <String, String>{};
    for (final header in headers) {
      final sample = columnsData[header]!.take(sampleLimit).toList();
      types[header] = _detectColumnTypeStatic(sample);
    }
    
    // Преобразуем значения в соответствии с типом
    final columnsInfo = <Map<String, dynamic>>[];
    for (final header in headers) {
      final raw = columnsData[header]!;
      final type = types[header]!;
      final converted = _convertValuesByType(raw, type);
      columnsInfo.add({'name': header, 'type': type, 'values': converted});
    }
    
    return {'name': fileName, 'columns': columnsInfo};
  }

  /// Парсит одну строку CSV с учетом кавычек
  static List<String> _parseLineStatic(String line, String delimiter) {
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

  /// Определяет тип колонки на основе сырых строк
  static String _detectColumnTypeStatic(List<String?> values) {
    int nonNullCount = 0;
    bool allNumeric = true;
    bool allDateTime = true;

    for (final v in values) {
      if (v == null || v.isEmpty) continue;
      nonNullCount++;
      if (double.tryParse(v.replaceAll(',', '.')) == null) allNumeric = false;
      if (DateTime.tryParse(v) == null) allDateTime = false;
    }

    if (nonNullCount == 0) return 'text';
    if (allNumeric) return 'numeric';
    if (allDateTime) return 'datetime';

    // Категориальная эвристика: количество уникальных менее 20% от ненулевых
    final unique = values.whereType<String>().toSet().length;
    if (unique < nonNullCount * 0.2) return 'categorical';
    return 'text';
  }

  /// Преобразует сырые строки в типизированные значения в зависимости от типа
  /// Принимает:
  /// - [raw] — список строковых значений колонки
  /// - [type] — определенный тип колонки ('numeric', 'datetime', 'categorical', 'text')
  /// Возвращает:
  /// - [List<dynamic>] — список значений в соответствующем типе
  static List<dynamic> _convertValuesByType(List<String?> raw, String type) {
    switch (type) {
      case 'numeric':
        return raw.map((v) {
          if (v == null || v.isEmpty) return null;
          return double.tryParse(v.replaceAll(',', '.'));
        }).toList();
      case 'datetime':
        return raw.map((v) {
          if (v == null || v.isEmpty) return null;
          return DateTime.tryParse(v)?.toIso8601String();
        }).toList();
      case 'categorical':
      case 'text':
      default:
        return raw.toList();
    }
  }

  /// Собирает объект Dataset из результата isolate
  Dataset _buildDatasetFromResult(Map<String, dynamic> result, String fileName) {
    final columnsData = result['columns'] as List;
    final columns = columnsData.map<DataColumn>((colMap) {
      final name = colMap['name'] as String;
      final type = colMap['type'] as String;
      final values = colMap['values'] as List;
      switch (type) {
        case 'numeric':
          return NumericColumn(name, values.cast<double?>());
        case 'datetime':
          return DateTimeColumn(
            name,
            values.map((v) => v != null ? DateTime.parse(v as String) : null).toList(),
          );
        case 'categorical':
          return CategoricalColumn(name, values.cast<String?>());
        default:
          return TextColumn(name, values.cast<String?>());
      }
    }).toList();
    return Dataset(name: fileName, columns: columns);
  }
}