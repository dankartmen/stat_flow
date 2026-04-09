import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
      
      final resultMap = await compute(_parseCsvInIsolate, (content, fileName, delimiter));
      return _buildDatasetFromResult(resultMap, fileName);
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


  /// Статическая функция для выполнения в isolate.
  /// Принимает кортеж (content, fileName, delimiter), возвращает сериализуемую Map.
  static Future<Map<String, dynamic>> _parseCsvInIsolate((String content, String fileName, String delimiter) args) async {
    final (content, fileName, delimiter) = args;
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
        .map((line) => _parseLineStatic(line, delimiter))
        .toList();

    // Собираем сырые значения по колонкам
    final columnsData = <String, List<String?>>{};
    for (int colIndex = 0; colIndex < headers.length; colIndex++) {
      final colValues = <String?>[];
      for (final row in rows) {
        if (colIndex < row.length) {
          colValues.add(row[colIndex]);
        } else {
          colValues.add(null);
        }
      }
      columnsData[headers[colIndex]] = colValues;
    }

    // Определяем тип каждой колонки и преобразуем значения
    final columnsInfo = <Map<String, dynamic>>[];
    for (final name in headers) {
      final raw = columnsData[name]!;
      final type = _detectColumnTypeStatic(raw);
      final convertedValues = _convertValuesByType(raw, type);
      columnsInfo.add({
        'name': name,
        'type': type,
        'values': convertedValues,
      });
    }

    return {
      'name': fileName,
      'columns': columnsInfo,
    };
  }

  /// Парсит одну строку CSV с учетом кавычек (статическая версия)
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