import 'dart:convert';
import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../dataset/dataset.dart';

/// {@template file_loader}
/// Загрузчик и парсер CSV-файлов для преобразования в структуру [Dataset]
/// 
/// Отвечает за:
/// - Выбор файла через системный диалог
/// - Чтение и декодирование CSV-содержимого
/// - Определение типов колонок (числовые, дата/время, категориальные, текстовые)
/// - Создание соответствующей структуры данных
/// {@endtemplate}
class FileLoader {
  /// Открывает диалог выбора файла и загружает выбранный CSV-файл
  /// 
  /// Возвращает:
  /// - [Future<Dataset>] — датасет, созданный из загруженного файла
  /// 
  /// Особенности:
  /// - Поддерживаются только CSV-файлы
  /// - Первая строка интерпретируется как заголовки колонок
  /// - Пустые строки игнорируются
  /// - Тип каждой колонки определяется автоматически
  /// 
  /// Выбрасывает:
  /// - [Exception] — если файл не выбран
  /// - [Exception] — если не удалось прочитать файл
  /// - [Exception] — если файл пуст
  Future<Dataset> getDataset() async {
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
      throw Exception('Не удалось прочитать файл');
    }

    final stream = http.ByteStream(file.readStream!);
    final bytes = await stream.toBytes();
    final content = utf8.decode(bytes);

    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('Файл пуст');
    }

    final headers = lines.first.split(',').map((e) => e.trim()).toList();

    final rows = lines
        .skip(1)
        .map((line) => line.split(',').map((e) => e.trim()).toList())
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
      name: file.name,
      columns: columns,
    );
  }

  /// Создает колонку соответствующего типа на основе анализа сырых данных
  /// 
  /// Принимает:
  /// - [name] — имя колонки
  /// - [rawValues] — сырые строковые значения из CSV
  /// 
  /// Возвращает:
  /// - [DataColumn] — типизированную колонку ([NumericColumn], [DateTimeColumn], 
  ///   [CategoricalColumn] или [TextColumn])
  /// 
  /// Особенности:
  /// - Сначала проверяется возможность числового типа
  /// - Затем проверяется тип дата/время
  /// - Затем проверяется категориальный тип (если уникальных значений < 20%)
  /// - Иначе создается текстовая колонка
  DataColumn _buildColumn(String name, List<String?> rawValues) {
    if (_isNumeric(rawValues)) {
      final values = rawValues.map((v) {
        if (v == null || v.isEmpty) return null;
        return double.tryParse(v);
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
    for (final v in values) {
      if (v == null || v.isEmpty) continue;
      if (double.tryParse(v) == null) return false;
    }
    return true;
  }

  /// Проверяет, можно ли интерпретировать значения как даты
  bool _isDateTime(List<String?> values) {
    for (final v in values) {
      if (v == null || v.isEmpty) continue;
      if (DateTime.tryParse(v) == null) return false;
    }
    return true;
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