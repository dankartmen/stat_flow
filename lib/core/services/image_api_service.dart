import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// {@template dataset_info}
/// Метаинформация о датасете изображений, полученная от сервера.
/// 
/// Содержит:
/// - Уникальный идентификатор датасета
/// - Имя датасета
/// - Общее количество изображений
/// - Распределение по классам (название класса → количество)
/// - Примеры путей к изображениям для каждого класса (первые несколько)
/// {@endtemplate}
class DatasetInfo {
  /// Уникальный идентификатор датасета на сервере.
  final String datasetId;

  /// Отображаемое имя датасета.
  final String name;

  /// Общее количество изображений во всех классах.
  final int totalImages;

  /// Карта: имя класса → количество изображений в этом классе.
  final Map<String, int> classCounts;

  /// Карта: имя класса → список путей к примерным изображениям (для предпросмотра).
  final Map<String, List<String>> samplePaths;

  /// {@macro dataset_info}
  DatasetInfo({
    required this.datasetId,
    required this.name,
    required this.totalImages,
    required this.classCounts,
    required this.samplePaths,
  });

  /// Создаёт экземпляр из JSON-ответа сервера.
  factory DatasetInfo.fromJson(Map<String, dynamic> json) {
    return DatasetInfo(
      datasetId: json['dataset_id'],
      name: json['name'],
      totalImages: json['total_images'],
      classCounts: Map<String, int>.from(json['class_counts']),
      samplePaths: Map<String, List<String>>.from(
          (json['sample_paths'] as Map).map((k, v) => MapEntry(k, List<String>.from(v)))),
    );
  }
}

/// {@template image_api_service}
/// Сервис для взаимодействия с бэкендом API для работы с датасетами изображений и обучения моделей.
/// 
/// Предоставляет методы:
/// - Загрузка zip-архива с датасетом
/// - Получение информации о датасете
/// - Предобработка изображений (изменение размера, нормализация, разбиение на train/val/test)
/// - Поиск существующих экспериментов
/// - Запуск обучения
/// - Получение деталей эксперимента (метрики, графики, модель)
/// - Скачивание файлов модели, графиков, архивов
/// {@endtemplate}
class ImageApiService {
  /// Базовый URL API (для Android эмулятора измените на http://10.0.2.2:8000).
  static const String baseUrl = 'http://localhost:8000';

  /// Загружает zip-архив с датасетом изображений на сервер.
  /// 
  /// Принимает:
  /// - [zipBytes] — байты zip-файла.
  /// 
  /// Возвращает:
  /// - JSON-ответ сервера, содержащий `dataset_id` и другую информацию.
  /// 
  /// При ошибке выбрасывает исключение.
  Future<Map<String, dynamic>> uploadDataset(Uint8List zipBytes) async {
    var uri = Uri.parse('$baseUrl/datasets/upload');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', zipBytes, filename: 'dataset.zip'));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  /// Получает метаинформацию о датасете по его идентификатору.
  Future<DatasetInfo> getDatasetInfo(String datasetId) async {
    var uri = Uri.parse('$baseUrl/datasets/$datasetId/info');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      return DatasetInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get info: ${response.body}');
    }
  }

  /// Запускает предобработку датасета изображений.
  /// 
  /// Принимает:
  /// - [datasetId] — идентификатор датасета.
  /// - [imgSize] — размер, до которого изменяются изображения (ширина=высота).
  /// - [normalization] — тип нормализации ('0-1' или 'mean-std').
  /// - [trainSplit], [valSplit], [testSplit] — пропорции разбиения (должны давать в сумме 1.0).
  /// 
  /// Возвращает JSON с подтверждением и, возможно, статистикой.
  Future<Map<String, dynamic>> preprocess(String datasetId, {
    required int imgSize,
    String normalization = '0-1',
    double trainSplit = 0.7,
    double valSplit = 0.15,
    double testSplit = 0.15,
  }) async {
    final uri = Uri.parse('$baseUrl/datasets/$datasetId/preprocess');
    final response = await http.post(uri, body: jsonEncode({
      'img_size': imgSize,
      'normalization': normalization,
      'train_split': trainSplit,
      'val_split': valSplit,
      'test_split': testSplit,
    }), headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Preprocess error: ${response.body}');
    }
  }

  /// Ищет существующий эксперимент с заданными гиперпараметрами.
  /// 
  /// Возвращает [ExperimentSummary] или `null`, если эксперимент не найден.
  Future<ExperimentSummary?> findExperiment(String datasetId, Hyperparams params) async {
    final uri = Uri.parse('$baseUrl/experiments/find');
    final response = await http.post(uri, body: jsonEncode({
      'dataset_id': datasetId,
      'hyperparams': params.toJson(),
    }), headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body == null) return null;
      return ExperimentSummary.fromJson(body);
    } else {
      throw Exception('Find experiment error: ${response.body}');
    }
  }

  /// Запускает новый эксперимент (обучение модели) с указанными гиперпараметрами.
  /// 
  /// Возвращает JSON с идентификатором эксперимента и статусом.
  Future<Map<String, dynamic>> startTraining(String datasetId, Hyperparams params) async {
    final uri = Uri.parse('$baseUrl/experiments/start');
    final response = await http.post(uri, body: jsonEncode({
      'dataset_id': datasetId,
      'hyperparams': params.toJson(),
    }), headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Start training error: ${response.body}');
    }
  }

  /// Получает детальную информацию об эксперименте (метрики, график, путь к модели).
  Future<ExperimentDetail> getExperimentDetail(String experimentId) async {
    final uri = Uri.parse('$baseUrl/experiments/$experimentId');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return ExperimentDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Get experiment error: ${response.body}');
    }
  }

  /// Возвращает список кратких сводок всех экспериментов для данного датасета.
  Future<List<ExperimentSummary>> getExperiments(String datasetId) async {
    final uri = Uri.parse('$baseUrl/datasets/$datasetId/experiments');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ExperimentSummary.fromJson(e)).toList();
    } else {
      throw Exception('List experiments error: ${response.body}');
    }
  }

  /// Скачивает файл обученной модели (обычно .h5 или .pt) в виде байтов.
  Future<List<int>> downloadModelBytes(String experimentId) async {
    final uri = Uri.parse('$baseUrl/experiments/$experimentId/model');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Download failed: ${response.body}');
    }
  }

  /// Скачивает график обучения (loss/accuracy) в виде байтов изображения (PNG).
  Future<List<int>> downloadPlotBytes(String experimentId) async {
    final uri = Uri.parse('$baseUrl/experiments/$experimentId/plot/file');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Download plot failed: ${response.body}');
    }
  }

  /// Скачивает архив со всеми артефактами эксперимента (модель, логи, графики).
  Future<List<int>> downloadArchiveBytes(String experimentId) async {
    final uri = Uri.parse('$baseUrl/experiments/$experimentId/archive');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Download archive failed: ${response.body}');
    }
  }
}

/// {@template hyperparams}
/// Гиперпараметры для обучения свёрточной нейронной сети.
/// 
/// Содержит:
/// - Количество свёрточных слоёв и их конфигурацию (фильтры, размер ядра)
/// - Dropout rate
/// - Оптимизатор (Adam, SGD и др.)
/// - Количество эпох
/// - Размер входного изображения и метод нормализации
/// {@endtemplate}
class Hyperparams {
  /// Количество свёрточных слоёв.
  int convLayers;

  /// Список количества фильтров для каждого свёрточного слоя.
  List<int> filters;

  /// Список размеров ядра (например, [3, 3]) для каждого слоя.
  List<int> kernelSize;

  /// Вероятность dropout (от 0.0 до 1.0) после свёрточных слоёв.
  double dropoutRate;

  /// Название оптимизатора ('adam', 'sgd', 'rmsprop').
  String optimizer;

  /// Количество эпох обучения.
  int epochs;

  /// Размер входных изображений (ширина = высота).
  int imgSize;

  /// Тип нормализации пикселей ('0-1' или 'mean-std').
  String normalization;

  /// {@macro hyperparams}
  Hyperparams({
    required this.convLayers,
    required this.filters,
    required this.kernelSize,
    required this.dropoutRate,
    required this.optimizer,
    required this.epochs,
    this.imgSize = 128,
    this.normalization = '0-1',
  });

  /// Преобразует гиперпараметры в JSON для отправки на сервер.
  Map<String, dynamic> toJson() => {
    'conv_layers': convLayers,
    'filters': filters,
    'kernel_size': kernelSize,
    'dropout_rate': dropoutRate,
    'optimizer': optimizer,
    'epochs': epochs,
    'img_size': imgSize,
    'normalization': normalization,
  };

  /// Создаёт экземпляр из JSON-ответа сервера.
  factory Hyperparams.fromJson(Map<String, dynamic> json) => Hyperparams(
    convLayers: json['conv_layers'],
    filters: List<int>.from(json['filters']),
    kernelSize: List<int>.from(json['kernel_size']),
    dropoutRate: (json['dropout_rate'] as num).toDouble(),
    optimizer: json['optimizer'],
    epochs: json['epochs'],
    imgSize: json['img_size'] ?? 128,
    normalization: json['normalization'] ?? '0-1',
  );
}

/// {@template experiment_summary}
/// Краткая сводка об эксперименте (для списка).
/// 
/// Содержит идентификатор, гиперпараметры, статус, дату создания и лучшие метрики.
/// {@endtemplate}
class ExperimentSummary {
  /// Уникальный идентификатор эксперимента.
  final String experimentId;

  /// Идентификатор датасета, на котором проводился эксперимент.
  final String datasetId;

  /// Гиперпараметры, использованные в эксперименте.
  final Hyperparams hyperparams;

  /// Статус эксперимента ('pending', 'running', 'completed', 'failed').
  final String status;

  /// Дата и время создания в ISO-формате.
  final String createdAt;

  /// Точность на тестовой выборке (может быть null, если эксперимент не завершён).
  final double? testAccuracy;

  /// Точность на валидационной выборке.
  final double? valAccuracy;

  /// {@macro experiment_summary}
  ExperimentSummary({
    required this.experimentId,
    required this.datasetId,
    required this.hyperparams,
    required this.status,
    required this.createdAt,
    this.testAccuracy,
    this.valAccuracy,
  });

  /// Создаёт экземпляр из JSON.
  factory ExperimentSummary.fromJson(Map<String, dynamic> json) => ExperimentSummary(
    experimentId: json['experiment_id'],
    datasetId: json['dataset_id'],
    hyperparams: Hyperparams.fromJson(json['hyperparams']),
    status: json['status'],
    createdAt: json['created_at'],
    testAccuracy: (json['test_accuracy'] as num?)?.toDouble(),
    valAccuracy: (json['val_accuracy'] as num?)?.toDouble(),
  );
}

/// {@template experiment_detail}
/// Детальная информация об эксперименте (для страницы результата).
/// 
/// Включает полные метрики (train/val/test loss/accuracy), график обучения в Base64,
/// а также путь к сохранённой модели.
/// {@endtemplate}
class ExperimentDetail {
  /// Уникальный идентификатор эксперимента.
  final String experimentId;

  /// Идентификатор датасета.
  final String datasetId;

  /// Гиперпараметры.
  final Hyperparams hyperparams;

  /// Статус эксперимента.
  final String status;

  /// Дата создания.
  final String createdAt;

  /// Карта метрик (например, {'train_loss': 0.23, 'val_accuracy': 0.89}).
  final Map<String, double>? metrics;

  /// Путь к файлу модели на сервере (для скачивания).
  final String? modelPath;

  /// График обучения в формате Base64 (PNG).
  final String? plotBase64;

  /// {@macro experiment_detail}
  ExperimentDetail({
    required this.experimentId,
    required this.datasetId,
    required this.hyperparams,
    required this.status,
    required this.createdAt,
    this.metrics,
    this.modelPath,
    this.plotBase64,
  });

  /// Создаёт экземпляр из JSON.
  factory ExperimentDetail.fromJson(Map<String, dynamic> json) => ExperimentDetail(
    experimentId: json['experiment_id'],
    datasetId: json['dataset_id'],
    hyperparams: Hyperparams.fromJson(json['hyperparams']),
    status: json['status'],
    createdAt: json['created_at'],
    metrics: json['metrics'] != null
        ? Map<String, double>.from(json['metrics'].map((k, v) => MapEntry(k, (v as num).toDouble())))
        : null,
    modelPath: json['model_path'],
    plotBase64: json['plot_base64'],
  );
}