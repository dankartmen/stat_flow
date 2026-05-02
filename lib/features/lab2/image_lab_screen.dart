import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stat_flow/features/bars/top_nav_bar.dart';
import '../../core/services/image_api_service.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/controls_style.dart';
import 'experiments_table.dart';
import 'experiment_detail_dialog.dart';
import 'comparison_dialog.dart';

/// {@template image_lab_screen}
/// Экран лабораторной работы по классификации изображений (птицы vs БПЛА).
/// Состоит из двух вкладок:
/// - "Обучение": загрузка датасета, настройка гиперпараметров, запуск тренировки.
/// - "Эксперименты": просмотр истории экспериментов, сравнение моделей.
///
/// Использует [ImageApiService] для взаимодействия с бэкендом.
/// Сохраняет идентификатор датасета в [SharedPreferences] для восстановления после перезапуска.
/// {@endtemplate}
class ImageLabScreen extends ConsumerStatefulWidget {
  /// {@macro image_lab_screen}
  const ImageLabScreen({super.key});

  @override
  ConsumerState<ImageLabScreen> createState() => _ImageLabScreenState();
}

/// {@template image_lab_screen_state}
/// Состояние экрана классификации изображений.
/// Управляет:
/// - Загрузкой и предобработкой датасета.
/// - Текущими гиперпараметрами.
/// - Запуском обучения и отображением результатов.
/// - Списком экспериментов и выбором для сравнения.
/// {@endtemplate}
class _ImageLabScreenState extends ConsumerState<ImageLabScreen> with SingleTickerProviderStateMixin {
  /// Сервис API.
  final ImageApiService _api = ImageApiService();

  /// Флаг загрузки (загрузка датасета, предобработка).
  bool _loading = false;

  /// Сообщение об ошибке.
  String? _error;

  /// Информация о текущем датасете.
  DatasetInfo? _info;

  /// Гиперпараметры модели (изменяемые пользователем).
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

  /// Флаг выполнения обучения.
  bool _training = false;

  /// Список экспериментов (история).
  List<ExperimentSummary> _experiments = [];

  /// Множество идентификаторов экспериментов, выбранных для сравнения.
  final Set<String> _selectedExperimentIds = {};

  /// Контроллер вкладок.
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedDatasetId(); // Восстанавливаем сохранённый датасет при запуске
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Загружает сохранённый идентификатор датасета из SharedPreferences,
  /// получает информацию с сервера и обновляет провайдеры.
  /// Если сохранённый ID невалиден – очищает его.
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
        ref.read(imageDatasetIdProvider.notifier).state = datasetId;
        _loadExperiments(); // Загружаем список экспериментов для этого датасета
      } catch (e) {
        setState(() {
          _error = 'Не удалось загрузить сохранённый датасет: $e';
          _loading = false;
        });
      }
    }
  }

  /// Загружает ZIP-архив датасета, выполняет предобработку и сохраняет информацию.
  /// После успешной загрузки обновляет [_info] и загружает список экспериментов.
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
      // Предобработка с текущими гиперпараметрами
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
      ref.read(imageDatasetIdProvider.notifier).state = datasetId;
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('image_dataset_id', datasetId);
      _loadExperiments();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Запускает обучение модели.
  /// Если эксперимент с такими гиперпараметрами уже существует – показывает его детали.
  /// Иначе запускает новое обучение, отображает результат и обновляет список экспериментов.
  Future<void> _startTraining() async {
    if (_info == null) return;
    setState(() => _training = true);
    try {
      // Проверяем, не проводился ли уже эксперимент
      final existing = await _api.findExperiment(_info!.datasetId, _hyperparams);
      if (existing != null) {
        final detail = await _api.getExperimentDetail(existing.experimentId);
        if (!mounted) return;
        showDialog(context: context, builder: (_) => ExperimentDetailDialog(detail: detail));
        setState(() => _training = false);
        return;
      }
      // Новый эксперимент
      final response = await _api.startTraining(_info!.datasetId, _hyperparams);
      final experimentId = response['experiment_id'];
      final detail = await _api.getExperimentDetail(experimentId);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => ExperimentDetailDialog(detail: detail));
      _loadExperiments(); // Обновляем историю
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _training = false);
    }
  }

  /// Загружает список экспериментов для текущего датасета.
  Future<void> _loadExperiments() async {
    if (_info == null) return;
    try {
      final experiments = await _api.getExperiments(_info!.datasetId);
      setState(() => _experiments = experiments);
    } catch (e) {
      debugPrint('Ошибка загрузки экспериментов: $e');
    }
  }

  /// Показывает диалог сравнения выбранных экспериментов.
  void _showComparison() {
    if (_selectedExperimentIds.length < 2) return;
    showDialog(
      context: context,
      builder: (_) => ComparisonDialog(
        experimentIds: _selectedExperimentIds.toList(),
        api: _api,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Column(children: [const TopNavBar(), Center(child: Text(_error!))])
              : Column(
                  children: [
                    const TopNavBar(),
                    // Строка с информацией о датасете (если загружен)
                    if (_info != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.dataset, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_info!.name} (${_info!.totalImages} изобр.)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.settings), text: 'Обучение'),
                        Tab(icon: Icon(Icons.history), text: 'Эксперименты'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTrainingTab(),
                          _buildExperimentsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Строит вкладку "Обучение".
  /// Содержит кнопку загрузки датасета (если не загружен) или форму гиперпараметров и кнопку "Обучить".
  Widget _buildTrainingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_info == null)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Загрузить ZIP-архив с датасетом'),
              onPressed: _uploadAndPreprocess,
            )
          else ...[
            const SizedBox(height: 8),
            buildSection(
              context: context,
              title: 'Гиперпараметры модели',
              icon: Icons.tune,
              child: _buildHyperparamsForm(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _training ? null : _startTraining,
              child: _training
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Обучить модель'),
            ),
          ],
        ],
      ),
    );
  }

  /// Строит вкладку "Эксперименты".
  /// Отображает список экспериментов с возможностью множественного выбора для сравнения.
  /// Если выбрано минимум 2 эксперимента, появляется кнопка "Сравнить выбранные".
  Widget _buildExperimentsTab() {
    if (_info == null) {
      return const Center(child: Text('Сначала загрузите датасет'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('История экспериментов', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadExperiments),
            ],
          ),
        ),
        Expanded(
          child: ExperimentsTable(
            experiments: _experiments,
            bestExperimentId: _experiments.isNotEmpty ? _experiments.first.experimentId : null,
            selectedIds: _selectedExperimentIds,
            onSelectionChanged: (ids) => setState(() {
              _selectedExperimentIds.clear();
              _selectedExperimentIds.addAll(ids);
            }),
            onTap: (exp) => _showExperimentDetail(exp.experimentId),
          ),
        ),
        if (_selectedExperimentIds.length >= 2)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: Text('Сравнить выбранные (${_selectedExperimentIds.length})'),
              onPressed: _showComparison,
            ),
          ),
      ],
    );
  }

  /// Показывает диалог с деталями конкретного эксперимента.
  void _showExperimentDetail(String experimentId) async {
    try {
      final detail = await _api.getExperimentDetail(experimentId);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => ExperimentDetailDialog(detail: detail));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  /// Строит форму для выбора гиперпараметров.
  /// Использует универсальный виджет [buildDropdown] из [controls_style].
  Widget _buildHyperparamsForm() {
    return Column(
      children: [
        buildDropdown<int>(
          context: context, label: 'Свёрточных слоёв', initialValue: _hyperparams.convLayers,
          items: [2, 3],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _hyperparams.convLayers = v;
              // Автоматически корректируем фильтры
              _hyperparams.filters = v == 3 ? [32, 64, 128] : [32, 64];
            });
          },
        ),
        const SizedBox(height: 12),
        buildDropdown<String>(
          context: context, label: 'Фильтры', initialValue: _hyperparams.filters.toString(),
          items: ['[32, 64]', '[32, 64, 128]'],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _hyperparams.filters = v == '[32, 64, 128]' ? [32, 64, 128] : [32, 64];
            });
          },
          displayName: (v) => v,
        ),
        const SizedBox(height: 12),
        buildDropdown<List<int>>(
          context: context, label: 'Размер ядра', initialValue: _hyperparams.kernelSize,
          items: [[3, 3], [5, 5]],
          onChanged: (v) { if (v != null) setState(() => _hyperparams.kernelSize = v); },
          displayName: (v) => v.toString(),
        ),
        const SizedBox(height: 12),
        buildDropdown<double>(
          context: context, label: 'Dropout', initialValue: _hyperparams.dropoutRate,
          items: [0.25, 0.5],
          onChanged: (v) { if (v != null) setState(() => _hyperparams.dropoutRate = v); },
          displayName: (v) => v.toString(),
        ),
        const SizedBox(height: 12),
        buildDropdown<String>(
          context: context, label: 'Оптимизатор', initialValue: _hyperparams.optimizer,
          items: ['adam', 'sgd'],
          onChanged: (v) { if (v != null) setState(() => _hyperparams.optimizer = v); },
        ),
        const SizedBox(height: 12),
        buildDropdown<int>(
          context: context, label: 'Эпохи', initialValue: _hyperparams.epochs,
          items: [3, 10, 20, 30, 50],
          onChanged: (v) { if (v != null) setState(() => _hyperparams.epochs = v); },
        ),
        const SizedBox(height: 12),
        buildDropdown<int>(
          context: context, label: 'Размер (px)', initialValue: _hyperparams.imgSize,
          items: [64, 128, 224, 640],
          onChanged: (v) { if (v != null) setState(() => _hyperparams.imgSize = v); },
        ),
        const SizedBox(height: 12),
        buildDropdown<String>(
          context: context, label: 'Нормализация', initialValue: _hyperparams.normalization,
          items: ['0-1', 'std'],
          onChanged: (v) { if (v != null) setState(() => _hyperparams.normalization = v); },
        ),
      ],
    );
  }
}