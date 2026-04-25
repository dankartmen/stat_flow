import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/core/providers/providers.dart';
import 'package:stat_flow/core/services/api_service.dart';

/// {@template model_training_screen}
/// Экран для обучения нейросетевой модели на загруженном датасете.
/// 
/// Позволяет выбрать целевой признак и признаки-фичи, запустить обучение
/// на серверной части (FastAPI) и просмотреть результаты экспериментов:
/// - Accuracy / Loss на train/val/test
/// - Время обучения
/// - Графики истории обучения
/// Подсвечивается лучшая модель по test accuracy.
/// {@endtemplate}
class ModelTrainingScreen extends ConsumerStatefulWidget {
  /// {@macro model_training_screen}
  const ModelTrainingScreen({super.key});

  @override
  ConsumerState<ModelTrainingScreen> createState() => _ModelTrainingScreenState();
}

/// Состояние экрана обучения модели.
/// Управляет выбором признаков, запуском обучения и отображением результатов.
class _ModelTrainingScreenState extends ConsumerState<ModelTrainingScreen> {
  /// Список имён колонок, используемых как признаки (features).
  /// Инициализируется в [initState] всеми колонками, кроме целевой и 'time'.
  List<String> _selectedFeatures = [];

  /// Имя целевой колонки (зависимая переменная).
  /// По умолчанию 'DEATH_EVENT' (для датасета heart failure).
  String _targetColumn = 'DEATH_EVENT';

  /// Флаг, указывающий на выполнение обучения в данный момент.
  bool _isTraining = false;

  /// Результат обучения, полученный от сервера.
  /// Содержит список экспериментов и общую информацию.
  TrainingResponse? _result;

  /// Текст ошибки, возникшей при обучении (если есть).
  String? _error;

  @override
  void initState() {
    super.initState();
    final dataset = ref.read(datasetProvider);
    if (dataset != null) {
      // По умолчанию выбираем все колонки, кроме целевой и 'time' (исключаем временную колонку, если она есть)
      _selectedFeatures = dataset.columns
          .map((c) => c.name)
          .where((name) => name != _targetColumn && name != 'time')
          .toList();
    }
  }

  /// Запускает процесс обучения: создаёт временный CSV-файл из текущего датасета,
  /// вызывает API и обрабатывает ответ или ошибку.
  Future<void> _startTraining() async {
    final dataset = ref.read(datasetProvider);
    if (dataset == null) return;

    // TODO(developer): Сохранять исходный путь к файлу в Dataset при загрузке,
    // чтобы избежать повторного создания CSV.
    // Создаём временный CSV из данных в памяти
    final csvContent = _datasetToCsv(dataset);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_dataset.csv');
    await tempFile.writeAsString(csvContent);

    setState(() {
      _isTraining = true;
      _error = null;
      _result = null;
    });

    try {
      final api = ApiService();
      final response = await api.trainModel(
        csvFile: tempFile,
        targetColumn: _targetColumn,
        featureColumns: _selectedFeatures,
      );
      setState(() {
        _result = response;
        _isTraining = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isTraining = false;
      });
    }
  }

  /// Преобразует объект [Dataset] в строку формата CSV с заголовками.
  /// Пустые (null) значения заменяются пустой строкой.
  String _datasetToCsv(Dataset dataset) {
    final buf = StringBuffer();
    // Заголовки колонок
    buf.writeln(dataset.columns.map((c) => c.name).join(','));
    // Построчное формирование CSV
    for (int i = 0; i < dataset.rowCount; i++) {
      final row = dataset.columns.map((c) {
        var val = c.data[i];
        if (val == null) return '';
        if (val is double) return val.toString();
        return val.toString();
      }).join(',');
      buf.writeln(row);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(datasetProvider);

    if (dataset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Обучение модели')),
        body: const Center(child: Text('Загрузите датасет для продолжения')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обучение нейросети'),
        actions: [
          if (!_isTraining)
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Обучить'),
              onPressed: _startTraining,
            ),
        ],
      ),
      body: _isTraining
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _buildResults(),
    );
  }

  /// Строит виджет с результатами обучения после успешного завершения.
  Widget _buildResults() {
    if (_result == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Нажмите "Обучить" для запуска экспериментов.'),
      );
    }

    final experiments = _result!.experiments;
    return Column(
      children: [
        // Карточка с общей информацией о разбиении данных
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Признаков: ${_result!.featureCount}'),
                Text('Обучающая: ${_result!.trainRows}'),
                Text('Тестовая: ${_result!.testRows}'),
              ],
            ),
          ),
        ),
        // Список экспериментов (моделей)
        Expanded(
          child: ListView.builder(
            itemCount: experiments.length,
            itemBuilder: (context, index) {
              final exp = experiments[index];
              // Подсветка лучшей модели
              final isBest = exp.id == _result!.bestModelId;
              return Card(
                color: isBest ? Colors.lightGreen[50] : null,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text(
                      'Модель #${exp.id}: ${exp.params['layers']} (${exp.params['activation']})'),
                  subtitle: Text(
                      'Test Acc: ${exp.testAccuracy.toStringAsFixed(3)} | Время: ${exp.trainingTimeSec}s'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Accuracy метрики
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              MetricTile('Train Acc', exp.trainAccuracy.toStringAsFixed(3)),
                              MetricTile('Val Acc', exp.valAccuracy.toStringAsFixed(3)),
                              MetricTile('Test Acc', exp.testAccuracy.toStringAsFixed(3)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Loss метрики
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              MetricTile('Train Loss', exp.trainLoss.toStringAsFixed(3)),
                              MetricTile('Val Loss', exp.valLoss.toStringAsFixed(3)),
                              MetricTile('Test Loss', exp.testLoss.toStringAsFixed(3)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // График обучения (base64 PNG)
                          if (exp.historyPlotBase64.isNotEmpty)
                            Image.memory(
                              base64Decode(exp.historyPlotBase64),
                              fit: BoxFit.contain,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// {@template metric_tile}
/// Маленькая карточка для отображения пары "название метрики → значение".
/// Используется внутри [ExpansionTile] для компактного представления Accuracy/Loss.
/// {@endtemplate}
class MetricTile extends StatelessWidget {
  /// Название метрики (например "Train Acc").
  final String label;
  /// Форматированное значение метрики (например "0.876").
  final String value;

  /// {@macro metric_tile}
  const MetricTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}