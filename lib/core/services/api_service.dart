import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// {@template train_result}
/// Результат обучения одной модели (эксперимента).
/// 
/// Содержит метрики качества и параметры модели:
/// - Точность и функцию потерь на train/val/test выборках
/// - Время обучения и количество эпох
/// - График истории обучения в формате Base64
/// {@endtemplate}
class TrainResult {
  /// Уникальный идентификатор эксперимента.
  final int id;

  /// Параметры модели (гиперпараметры, архитектура).
  final Map<String, dynamic> params;

  /// Точность на тестовой выборке.
  final double testAccuracy;

  /// Точность на обучающей выборке.
  final double trainAccuracy;

  /// Точность на валидационной выборке.
  final double valAccuracy;

  /// Функция потерь на тестовой выборке.
  final double testLoss;

  /// Функция потерь на обучающей выборке.
  final double trainLoss;

  /// Функция потерь на валидационной выборке.
  final double valLoss;

  /// Количество обученных эпох.
  final int epochsTrained;

  /// Время обучения в секундах.
  final double trainingTimeSec;

  /// График истории обучения (потери и точность по эпохам) в формате Base64.
  final String historyPlotBase64;

  /// {@macro train_result}
  TrainResult({
    required this.id,
    required this.params,
    required this.testAccuracy,
    required this.trainAccuracy,
    required this.valAccuracy,
    required this.testLoss,
    required this.trainLoss,
    required this.valLoss,
    required this.epochsTrained,
    required this.trainingTimeSec,
    required this.historyPlotBase64,
  });

  /// Создаёт [TrainResult] из JSON-ответа сервера.
  ///
  /// Принимает:
  /// - [json] - десериализованный JSON-объект.
  ///
  /// Возвращает:
  /// - экземпляр [TrainResult].
  factory TrainResult.fromJson(Map<String, dynamic> json) {
    return TrainResult(
      id: json['id'],
      params: json['params'],
      testAccuracy: (json['test_accuracy'] as num).toDouble(),
      trainAccuracy: (json['train_accuracy'] as num).toDouble(),
      valAccuracy: (json['val_accuracy'] as num).toDouble(),
      testLoss: (json['test_loss'] as num).toDouble(),
      trainLoss: (json['train_loss'] as num).toDouble(),
      valLoss: (json['val_loss'] as num).toDouble(),
      epochsTrained: json['epochs_trained'],
      trainingTimeSec: (json['training_time_sec'] as num).toDouble(),
      historyPlotBase64: json['history_plot'],
    );
  }
}

/// {@template training_response}
/// Полный ответ сервера после запуска обучения.
/// 
/// Содержит:
/// - Список всех проведённых экспериментов (моделей)
/// - ID лучшей модели
/// - Информацию о предобработке данных
/// - Размеры выборок и количество признаков
/// {@endtemplate}
class TrainingResponse {
  /// Список всех обученных моделей (экспериментов).
  final List<TrainResult> experiments;

  /// Идентификатор лучшей модели (из experiments).
  final int bestModelId;

  /// Информация о предобработке данных (нормализация, кодирование категорий и т.п.).
  final Map<String, dynamic> preprocessingInfo;

  /// Количество строк в обучающей выборке.
  final int trainRows;

  /// Количество строк в тестовой выборке.
  final int testRows;

  /// Количество признаков, использованных для обучения.
  final int featureCount;

  /// {@macro training_response}
  TrainingResponse({
    required this.experiments,
    required this.bestModelId,
    required this.preprocessingInfo,
    required this.trainRows,
    required this.testRows,
    required this.featureCount,
  });

  /// Создаёт [TrainingResponse] из JSON-ответа сервера.
  ///
  /// Принимает:
  /// - [json] - десериализованный JSON-объект.
  ///
  /// Возвращает:
  /// - экземпляр [TrainingResponse].
  factory TrainingResponse.fromJson(Map<String, dynamic> json) {
    final experimentsJson = json['experiments']['experiments'] as List;
    return TrainingResponse(
      experiments: experimentsJson.map((e) => TrainResult.fromJson(e)).toList(),
      bestModelId: json['experiments']['best_model_id'],
      preprocessingInfo: json['preprocessing_info'],
      trainRows: json['train_rows'],
      testRows: json['test_rows'],
      featureCount: json['feature_count'],
    );
  }
}

/// {@template api_service}
/// Сервис для взаимодействия с бэкендом (FastAPI) для обучения нейронных сетей.
/// 
/// Отправляет CSV-файл с данными на сервер и получает результаты обучения.
/// Адрес сервера: http://localhost:8000 (при необходимости заменить на реальный).
/// {@endtemplate}
class ApiService {
  /// Базовый URL для API-запросов.
  /// 
  /// Для Android-эмулятора localhost соответствует 10.0.2.2,
  /// но здесь оставлен как localhost:8000 для удобства разработки.
  static const String baseUrl = 'http://localhost:8000';

  /// Запускает обучение модели на сервере.
  ///
  /// Принимает:
  /// - [csvFile] - CSV-файл с данными для обучения.
  /// - [targetColumn] - имя целевой колонки (предсказываемая переменная).
  /// - [featureColumns] - опциональный список колонок-признаков (если не указаны, используются все остальные).
  ///
  /// Возвращает:
  /// - [TrainingResponse] с результатами всех экспериментов.
  ///
  /// При ошибке выбрасывает исключение с описанием.
  Future<TrainingResponse> trainModel({
    required File csvFile,
    required String targetColumn,
    List<String>? featureColumns,
  }) async {
    var uri = Uri.parse('$baseUrl/train');
    var request = http.MultipartRequest('POST', uri);

    // Добавляем файл
    request.files.add(await http.MultipartFile.fromPath('file', csvFile.path));
    
    // Добавляем текстовые поля
    request.fields['target_column'] = targetColumn;
    if (featureColumns != null && featureColumns.isNotEmpty) {
      request.fields['feature_columns'] = jsonEncode(featureColumns);
    }

    // Отправляем запрос
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return TrainingResponse.fromJson(json);
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Unknown error';
      throw Exception('Ошибка обучения: $error');
    }
  }
}