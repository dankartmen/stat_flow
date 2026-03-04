import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../dataset/dataset.dart';

/// {@template file_loader}
/// Класс для загрузки данных
/// {@endtemplate}
class FileLoader {
  Future<Dataset> getDataset() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'csv'
      ],
      withData: false,
      withReadStream: true
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('Файлы не были выбраны или программа выбора файлов была отменена');
    }
    final file = result.files.first;
    final fileName = file.name;
    final fileReadStream = file.readStream;
    if (fileReadStream == null) {
      throw Exception('Не удается прочитать файл из нулевого потока');
    }
    final stream = http.ByteStream(fileReadStream);
    final bytes = await stream.toBytes();
    final content = utf8.decode(bytes);

    // Разбор CSV
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      throw Exception('Файл пуст');
    }
    
    // Предполагаем, что первая строка - заголовки
    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final dataRows = lines.skip(1).map((line) {
      return line.split(',').map((cell) => cell.trim()).toList();
    }).toList();
    
    // Вывод информации в консоль
    log('=== ИНФОРМАЦИЯ О CSV ФАЙЛЕ ===', name: "FileLoader");
    log('Имя файла: ${file.name}', name: "FileLoader");
    log('Размер файла: ${file.size} байт', name: "FileLoader");
    log('Количество строк: ${lines.length}', name: "FileLoader");
    log('Количество колонок: ${headers.length}', name: "FileLoader");
    
    log('Заголовки:', name: "FileLoader");
    for (var i = 0; i < headers.length; i++) {
      log('  [${i+1}] ${headers[i]}', name: "FileLoader");
    }
    log('=== КОНЕЦ ИНФОРМАЦИИ ===', name: "FileLoader");

    // Создаем колонки для Dataset
    final List<DataColumn> columns = [];

    for (int i = 0; i < headers.length; i++) {
      // Собираем все значения для текущей колонки
      final List<dynamic> rawValues = [];
        for (var row in dataRows) {
          if (i < row.length) {
            rawValues.add(_tryParseValue(row[i]));
          } else {
            rawValues.add(null);
          }
        }

      // Определяем тип на основе всех значений
      final columnType = _determineColumnType(rawValues);
      
      // Для числовых колонок - приводим всё к double
      List<dynamic> cleanValues;
      if (columnType == ColumnType.numeric) {
        cleanValues = rawValues.map((v) {
          if (v is num) return v.toDouble(); 
          if (v is String && double.tryParse(v) != null) return double.parse(v); 
          return null; // всё остальное в null
        }).toList();
      } else {
        cleanValues = rawValues; // для остальных типов оставляем как есть
      }
      // Создаем колонку
      columns.add(DataColumn(
        name: headers[i],
        type: columnType,
        values: cleanValues,
      ));
    }

    return Dataset(
      name: fileName,
      columns: columns,
    );
  }

  
  /// Пытается преобразовать строковое значение в соответствующий тип
  dynamic _tryParseValue(String value) {
    if (value.isEmpty) return null;
    
    // Пробуем распарсить как число (int или double)
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;
    
    // Пробуем распарсить как дату (в разных форматах)
    try {
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) return dateTime;
    } catch (_) {}
    
    // Если ничего не подошло, возвращаем как строку
    return value;
  }
  
  /// Определяет тип колонки на основе значений
  ColumnType _determineColumnType(List<dynamic> values) {
    bool allNull = true;
    bool allNumeric = true;
    bool allDateTime = true;
    final nonNullValues = <dynamic>[];
    
    for (var v in values) {
      if (v == null) continue;
      
      allNull = false;
      nonNullValues.add(v);
      
      if (v is! num) allNumeric = false;
      if (v is! DateTime) allDateTime = false;
    }
    
    if (allNull) return ColumnType.text;
    if (allNumeric) return ColumnType.numeric;
    if (allDateTime) return ColumnType.datetime;
    
    // Если смесь типов или строки - проверяем на категориальность
    final uniqueValues = nonNullValues.toSet().length;
    if (uniqueValues < nonNullValues.length * 0.2) {
      return ColumnType.categorical;
    }
    
    return ColumnType.text;
  }
}



