import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stat_flow/features/bars/top_nav_bar.dart';
import '../../core/services/image_api_service.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/controls_style.dart';
import 'experiment_detail_dialog.dart';

/// {@template image_lab_screen}
/// Экран для лабораторной работы по классификации изображений (птицы vs БПЛА).
/// Позволяет загружать ZIP-архив с датасетом, выполнять предобработку,
/// настраивать гиперпараметры и запускать обучение модели.
/// {@endtemplate}
class ImageLabScreen extends ConsumerStatefulWidget {
  /// {@macro image_lab_screen}
  const ImageLabScreen({super.key});

  @override
  ConsumerState<ImageLabScreen> createState() => _ImageLabScreenState();
}

/// {@template image_lab_screen_state}
/// Состояние экрана классификации изображений.
/// Управляет загрузкой датасета, предобработкой, тренировкой и отображением информации.
/// {@endtemplate}
class _ImageLabScreenState extends ConsumerState<ImageLabScreen> {
  /// Сервис для взаимодействия с API классификации изображений.
  final ImageApiService _api = ImageApiService();

  /// Индикатор загрузки (загрузка датасета, предобработка).
  bool _loading = false;

  /// Сообщение об ошибке (если есть).
  String? _error;

  /// Информация о текущем загруженном датасете.
  DatasetInfo? _info;

  /// Гиперпараметры модели (значения по умолчанию).
  final Hyperparams _hyperparams = Hyperparams(
    convLayers: 2,
    filters: [32, 64],
    kernelSize: [3, 3],
    dropoutRate: 0.25,
    optimizer: 'adam',
    epochs: 20,
    imgSize: 128,
    normalization: '0-1',
  );

  /// Индикатор выполнения обучения.
  bool _training = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDatasetId(); // При старте проверяем, есть ли сохранённый датасет
  }

  /// Загружает сохранённый идентификатор датасета из SharedPreferences
  /// и получает его информацию с сервера.
  Future<void> _loadSavedDatasetId() async {
    final prefs = await SharedPreferences.getInstance();
    final datasetId = prefs.getString('image_dataset_id');
    if (datasetId != null) {
      try {
        setState(() => _loading = true);
        final info = await _api.getDatasetInfo(datasetId);
        setState(() {
          _info = info;
          _loading = false;
        });
        ref.read(imageDatasetInfoProvider.notifier).state = info;
      } catch (e) {
        setState(() {
          _error = 'Не удалось загрузить сохранённый датасет: $e';
          _loading = false;
        });
      }
    }
  }

  /// Загружает ZIP-архив датасета, выполняет предобработку (изменение размера, нормализацию, разбиение)
  /// и сохраняет информацию о датасете.
  Future<void> _uploadAndPreprocess() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bytes = result.files.single.bytes!;
      final uploadResp = await _api.uploadDataset(bytes);
      final datasetId = uploadResp['dataset_id'];
      // Автоматическая предобработка с параметрами из _hyperparams
      await _api.preprocess(
        datasetId,
        imgSize: _hyperparams.imgSize,
        normalization: _hyperparams.normalization,
        trainSplit: 0.7,
        valSplit: 0.15,
        testSplit: 0.15,
      );
      final info = await _api.getDatasetInfo(datasetId);
      setState(() {
        _info = info;
        _loading = false;
      });
      ref.read(imageDatasetInfoProvider.notifier).state = info;
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('image_dataset_id', datasetId);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Запускает обучение модели на текущем датасете.
  /// Перед запуском проверяет, не существует ли уже эксперимента с такими же гиперпараметрами.
  /// После запуска обучения необходимо обновить список экспериментов (TODO).
  Future<void> _startTraining() async {
    if (_info == null) return;
    setState(() => _training = true);
    try {
      // Проверяем существование эксперимента
      final existing = await _api.findExperiment(_info!.datasetId, _hyperparams);
      if (existing != null) {
        // Загружаем детали существующего эксперимента и показываем диалог
        final detail = await _api.getExperimentDetail(existing.experimentId);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => ExperimentDetailDialog(detail: detail),
        );
        setState(() => _training = false);
        return;
      }

      // Новый эксперимент: запускаем обучение
      final response = await _api.startTraining(_info!.datasetId, _hyperparams);
      final experimentId = response['experiment_id'];

      // Сразу загружаем детали (обучение синхронное, результат уже есть)
      final detail = await _api.getExperimentDetail(experimentId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => ExperimentDetailDialog(detail: detail),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _training = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TopNavBar(),
                      if (_info == null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Загрузить ZIP-архив с датасетом'),
                          onPressed: _uploadAndPreprocess,
                        )
                      else ...[
                        // Карточка с информацией о датасете
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Датасет: ${_info!.name}'),
                                Text('Всего изображений: ${_info!.totalImages}'),
                                Text('Птиц: ${_info!.classCounts['bird']}'),
                                Text('Дронов: ${_info!.classCounts['drone']}'),
                              ],
                            ),
                          ),
                        ),
                        if (_info != null) ...[
                          const SizedBox(height: 16),
                          buildSection(
                            context: context,
                            title: 'Гиперпараметры модели',
                            icon: Icons.tune,
                            child: _buildHyperparamsForm(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _training ? null : _startTraining,
                            child: _training ? const CircularProgressIndicator() : const Text('Обучить модель'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHyperparamsForm() {
    return Column(
      children: [
        buildDropdown<int>(
          context: context,
          label: 'Количество свёрточных слоёв',
          initialValue: _hyperparams.convLayers,
          items: [2, 3],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _hyperparams.convLayers = val;
                // Автоматически корректируем фильтры
                if (val == 2) {
                  _hyperparams.filters = [32, 64];
                } else {
                  _hyperparams.filters = [32, 64, 128];
                }
              });
            }
          },
        ),
        const SizedBox(height: 16),
        buildDropdown<String>(
          context: context,
          label: 'Фильтры',
          initialValue: _hyperparams.filters.toString(),
          items: ['[32, 64]', '[32, 64, 128]'],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _hyperparams.filters = val == '[32, 64, 128]' ? [32, 64, 128] : [32, 64];
              });
            }
          },
          displayName: (v) => v,
        ),
        const SizedBox(height: 16),
        buildDropdown<List<int>>(
          context: context,
          label: 'Размер ядра',
          initialValue: _hyperparams.kernelSize,
          items: [
            [3, 3],
            [5, 5]
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _hyperparams.kernelSize = val);
            }
          },
          displayName: (v) => v.toString(),
        ),
        const SizedBox(height: 16),
        buildDropdown<double>(
          context: context,
          label: 'Dropout rate',
          initialValue: _hyperparams.dropoutRate,
          items: [0.25, 0.5],
          onChanged: (val) {
            if (val != null) {
              setState(() => _hyperparams.dropoutRate = val);
            }
          },
          displayName: (v) => v.toString(),
        ),
        const SizedBox(height: 16),
        buildDropdown<String>(
          context: context,
          label: 'Оптимизатор',
          initialValue: _hyperparams.optimizer,
          items: ['adam', 'sgd'],
          onChanged: (val) {
            if (val != null) {
              setState(() => _hyperparams.optimizer = val);
            }
          },
        ),
        const SizedBox(height: 16),
        buildDropdown<int>(
          context: context,
          label: 'Количество эпох',
          initialValue: _hyperparams.epochs,
          items: [3, 10, 20, 30, 50],
          onChanged: (val) {
            if (val != null) {
              setState(() => _hyperparams.epochs = val);
            }
          },
        ),
        const SizedBox(height: 16),
        buildDropdown<int>(
          context: context,
          label: 'Размер изображения (px)',
          initialValue: _hyperparams.imgSize,
          items: [64, 128, 224, 640],
          onChanged: (val) {
            if (val != null) {
              setState(() => _hyperparams.imgSize = val);
            }
          },
        ),
        const SizedBox(height: 16),
        buildDropdown<String>(
          context: context,
          label: 'Нормализация',
          initialValue: _hyperparams.normalization,
          items: ['0-1', 'std'],
          onChanged: (val) {
            if (val != null) {
              setState(() => _hyperparams.normalization = val);
            }
          },
        ),
      ],
    );
  }
}