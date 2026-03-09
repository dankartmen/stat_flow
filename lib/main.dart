import 'dart:developer';

import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/statistics/statistic_result.dart';
import 'features/charts/heatmap/widgets/heatmap_section.dart';
import 'core/loader/csv_loader.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'features/table/grid/syncfusion_grid_data.dart';

  void main() {
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'CSV File Loader',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate
        ],
        supportedLocales: [
          const Locale('ru', 'RU'),
        ],
        home: const FileLoaderScreen(),
      );
    }
  }

  /// Главный экран приложения для загрузки и отображения файлов.
  class FileLoaderScreen extends StatefulWidget {
    const FileLoaderScreen({super.key});

    @override
    State<FileLoaderScreen> createState() => _FileLoaderScreenState();
  }

  class _FileLoaderScreenState extends State<FileLoaderScreen> {
    /// Сервис для загрузки файлов
    final CsvLoader _csvLoader = CsvLoader();

    /// Флаг состояния загрузки
    bool _isLoading = false;

    /// Флаг для показа таблицы
    bool _isTableVisible = false;

    /// Датасет
    Dataset? _dataset;
    /// Состояние для показа статистики
    bool _showStatistics = false;
    
    SyncfusionGridData? _gridData;

    /// Состояние для плавающего окна
    Offset _windowPosition = const Offset(80, 80);
    Size _windowSize = const Size(720, 520);
    final Size _minSize = const Size(380, 280);

    /// Состояние для второго плавающего окна (SfDataGrid)
    Offset _windowPositionSf = const Offset(200, 200);
    Size _windowSizeSf = const Size(720, 520);

    double _progress = 0;

    @override
    void initState(){
      super.initState();
    }

    /// Загружает файл и обновляет состояние
    /// 
    /// Показывает индикатор загрузки, обрабатывает ошибки
    /// и конвертирует данные в формат PlutoGrid.
    Future<void> _loadFile() async {
      setState(() {
        _isLoading = true;
        _showStatistics = false;
        _progress = 0;
      });

      try {
        // Загружаем датасет
        final loadedDataset = await _csvLoader.getDataset(
          onProgress: (p) {
            setState(() {
              _progress = p;
            });
          },
        );

        final converter = SyncfusionGridConverter();
        final gridData = converter.convert(loadedDataset);

        setState(() {
          _isLoading = false;
          _isTableVisible = true;
          _showStatistics = true;
          _dataset = loadedDataset;
          _gridData = gridData;
          _windowPosition = const Offset(80, 80);
          _windowSize = const Size(720, 520);
        });
      } catch (e) {
        setState(() => _isLoading = false);
        log('Ошибка загрузки: $e');
        _showErrorSnackBar(e);
      }
    }

    /// Показывает сообщение об ошибке в SnackBar
    void _showErrorSnackBar(Object error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }

    /// Строит экран приветствия с кнопкой загрузки.
    ///
    /// Отображается, когда данные еще не загружены.
    Widget _buildEmptyState() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 80,
                color: Colors.blue.shade300,
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Загрузите CSV файл',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Выберите CSV файл для загрузки и анализа данных',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Выбрать файл',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }


    /// Строит второе плавающее окно с таблицей данных (SfDataGrid).
    ///
    /// Окно можно:
    /// - Перетаскивать за заголовок
    /// - Закрыть кнопкой закрытия
    /// - Изменять размер через отдельный хендлер
    Widget _buildFloatingTableSf() {
      return Positioned(
        left: _windowPosition.dx,
        top: _windowPosition.dy,
        width: _windowSizeSf.width,
        height: _windowSizeSf.height,
        child: Material(
          elevation: 8, // Тень для эффекта "парения"
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Заголовок + перетаскивание
              GestureDetector(
                // Перетаскивание за заголовок
                onPanUpdate: (details) {
                  setState(() {
                    _windowPositionSf += details.delta; // Обновляем позицию
                  });
                },
                child: Container(
                  color: Colors.green[800],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Таблица данных (SfDataGrid)",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isTableVisible = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              //  Таблица
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SfDataGrid(
                    /// Источник данных для таблицы, содержащий строки и логику их отображения
                    source: _gridData!.source,
                    /// Список колонок таблицы с их конфигурациями
                    columns: _gridData!.columns,
                    /// Видимость линий сетки между ячейками (горизонтальные и вертикальные линии)
                    gridLinesVisibility: GridLinesVisibility.both,
                    /// Видимость линий сетки в заголовке колонок
                    headerGridLinesVisibility: GridLinesVisibility.both,
                    /// Разрешает сортировку колонок по клику на заголовок
                    allowSorting: true,
                    /// Разрешает сортировку по нескольким колонкам одновременно
                    allowMultiColumnSorting: true,
                    /// Разрешает три состояния сортировки (возрастание, убывание, нет сортировки)
                    allowTriStateSorting: true,
                    /// Показывает номера порядка сортировки при мультисортировке
                    showSortNumbers: true,
                    /// Тип жеста для активации сортировки (tap - одиночный клик, doubleTap - двойной)
                    sortingGestureType: SortingGestureType.tap,
                    /// Разрешает фильтрацию данных в колонках
                    allowFiltering: true,
                    /// Разрешает изменение ширины колонок пользователем
                    allowColumnsResizing: true,
                    /// Разрешает pull-to-refresh для обновления данных
                    allowPullToRefresh: false,
                    /// Разрешает свайпинг строк для дополнительных действий
                    allowSwiping: false,
                    /// Максимальное смещение при свайпе (в пикселях)
                    swipeMaxOffset: 200.0,
                    /// Callback, вызываемый при начале свайпа строки
                    onSwipeStart: (details) {
                      // Можно добавить логику начала свайпа
                      return true;
                    },
                    /// Callback, вызываемый при обновлении свайпа
                    // onSwipeUpdate: (details) {
                    //   // Логика обновления свайпа
                    //   null
                    // },
                    /// Callback, вызываемый при завершении свайпа
                    onSwipeEnd: (details) {
                      // Логика завершения свайпа
                    },
                    /// Builder для действий при свайпе слева (start)
                    // startSwipeActionsBuilder: (context, rowIndex) {
                    //   return Container(); // Пустой контейнер, если нет действий
                    // },
                    // /// Builder для действий при свайпе справа (end)
                    // endSwipeActionsBuilder: (context, rowIndex) {
                    //   return Container(); // Пустой контейнер, если нет действий
                    // },
                    /// Режим выбора строк (single - одна строка, multiple - несколько, none - нет выбора)
                    selectionMode: SelectionMode.multiple,
                    /// Режим навигации по таблице (cell - по ячейкам, row - по строкам)
                    navigationMode: GridNavigationMode.cell,
                    /// Разрешает редактирование ячеек
                    allowEditing: false,
                    /// Тип жеста для редактирования (tap - клик, doubleTap - двойной клик)
                    editingGestureType: EditingGestureType.doubleTap,
                    /// Показывает колонку с чекбоксами для выбора строк
                    showCheckboxColumn: true,
                    /// Настройки колонки чекбоксов (ширина, цвет и т.д.)
                    checkboxColumnSettings: const DataGridCheckboxColumnSettings(
                      width: 50,
                      showCheckboxOnHeader: true,
                    ),
                    /// Показывает иконку в заголовке колонки при наведении курсора
                    showColumnHeaderIconOnHover: true,
                    /// Режим определения ширины колонок (fitByCellValue - по содержимому, fitByColumnName - по имени, none - фиксированная)
                    columnWidthMode: ColumnWidthMode.fitByCellValue,
                    /// Объект для управления шириной колонок
                    columnSizer: null,
                    /// Ширина колонок по умолчанию (в пикселях)
                    defaultColumnWidth: 120.0,
                    /// Высота строк данных (в пикселях)
                    rowHeight: 40.0,
                    /// Высота строки заголовков колонок (в пикселях)
                    headerRowHeight: 50.0,
                    /// Высота футера таблицы (в пикселях)
                    footerHeight: 0.0,
                    /// Всегда показывать полосы прокрутки (даже если контент помещается)
                    isScrollbarAlwaysShown: false,
                    /// Физика прокрутки для горизонтальной полосы (определяет поведение прокрутки)
                    horizontalScrollPhysics: const ClampingScrollPhysics(),
                    /// Физика прокрутки для вертикальной полосы (определяет поведение прокрутки)
                    verticalScrollPhysics: const ClampingScrollPhysics(),
                    /// Контроллер для управления таблицей программно
                    controller: null,
                    /// Количество замороженных колонок слева (не прокручиваются)
                    frozenColumnsCount: 0,
                    /// Количество замороженных колонок в футере
                    footerFrozenColumnsCount: 0,
                    /// Количество замороженных строк сверху
                    frozenRowsCount: 0,
                    /// Callback для определения высоты строки динамически
                    onQueryRowHeight: (rowIndex) {
                      return 40.0; // Фиксированная высота
                    },
                    /// Callback при обновлении размера колонки
                    // onColumnResizeUpdate: (details) {
                    //   // Логика при изменении размера колонки
                    // },
                    /// Callback при клике на ячейку
                    onCellTap: (details) {
                      // Логика при клике на ячейку
                    },
                    /// Callback при двойном клике на ячейку
                    onCellDoubleTap: (details) {
                      // Логика при двойном клике
                    },
                    /// Callback при правом клике на ячейку
                    onCellSecondaryTap: (details) {
                      // Логика при правом клике
                    },
                    /// Callback при долгом нажатии на ячейку
                    onCellLongPress: (details) {
                      // Логика при долгом нажатии
                    },
                    /// Callback при изменении выбора строк
                    onSelectionChanged: (addedRows, removedRows) {
                      // Логика при изменении выбора
                    },
                    /// Callback при активации ячейки (фокус)
                    onCurrentCellActivated: (oldRowColumnIndex, newRowColumnIndex) {
                      // Логика при активации ячейки
                    },
                    /// Callback при клике на заголовок колонки
                    // onColumnHeaderTap: (details) {
                    //   // Логика при клике на заголовок
                    // },
                    /// Подсвечивать строку при наведении курсора
                    highlightRowOnHover: true,
                    /// Цвет подсветки строки при наведении
                    /// Builder для виджета "загрузить больше" в конце таблицы
                    loadMoreViewBuilder: (context, loadMoreRows) {
                      return Container(); // Пустой, если не используется
                    },
                    /// Сжимать строки по содержимому (для оптимизации производительности)
                    shrinkWrapRows: false,
                    /// Режим стека (для мобильных устройств, сворачивает колонки)
                  ),
                ),
              ),


            ],
          ),
        ),
      );
    }

    /// Строит хендлер для изменения размера плавающего окна.
    ///
    /// Расположен в правом нижнем углу окна и позволяет
    /// изменять размер с учетом минимальных ограничений.
    Widget _buildResizeHandle() {
      return Positioned(
        right: 0,
        bottom: 0,
        child: GestureDetector(
          // Изменение размера
          onPanUpdate: (details) {
            setState(() {
              double newWidth = _windowSize.width + details.delta.dx;
              double newHeight = _windowSize.height + details.delta.dy;

              // Ограничения минимального размера
              newWidth = newWidth.clamp(_minSize.width, double.infinity);
              newHeight = newHeight.clamp(_minSize.height, double.infinity);

              _windowSize = Size(newWidth, newHeight);
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.open_in_full,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    /// Строит хендлер для изменения размера второго плавающего окна (SfDataGrid).
    ///
    /// Расположен в правом нижнем углу окна и позволяет
    /// изменять размер с учетом минимальных ограничений.
    Widget _buildResizeHandleSf() {
      return Positioned(
        left: _windowPositionSf.dx + _windowSizeSf.width - 32,
        top: _windowPositionSf.dy + _windowSizeSf.height - 32,
        child: GestureDetector(
          // Изменение размера
          onPanUpdate: (details) {
            setState(() {
              double newWidth = _windowSizeSf.width + details.delta.dx;
              double newHeight = _windowSizeSf.height + details.delta.dy;

              // Ограничения минимального размера
              newWidth = newWidth.clamp(_minSize.width, double.infinity);
              newHeight = newHeight.clamp(_minSize.height, double.infinity);

              _windowSizeSf = Size(newWidth, newHeight);
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.open_in_full,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stat Flow — Загрузчик данных'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: _gridData != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _gridData = null;
                        _showStatistics = false;
                      });
                    },
                    tooltip: 'Загрузить другой файл',
                  ),
                ]
              : null,
        ),
        body: Stack(
          children: [
            // Основной контент
            _buildMainContent(),

            // Плавающее окно с таблицей
            if (_isTableVisible == true) ...[
              _buildResizeHandle(),
              _buildFloatingTableSf(),
              _buildResizeHandleSf(),
            ],
          ],
        ),
        
        
        drawer: Drawer(
          width: 200,
          child: _buildDrawerContent(),
        ),
      );
    }

    /// Строит содержимое бокового меню (drawer).
    ///
    /// Содержит:
    /// - Заголовок с информацией о состоянии
    /// - Пункты навигации и управления
    /// - Информацию о программе
    Widget _buildDrawerContent() {
      return Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Stat Flow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _gridData != null ? 'Данные загружены' : 'Нет данных',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Загрузить данные'),
                  onTap: () {
                    Navigator.pop(context); // Закрываем drawer
                    _loadFile();
                  },
                ),
                if (_gridData != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: const Text('Показать таблицу'),
                    subtitle: const Text('Плавающее окно'),
                    onTap: () {
                      if (_isTableVisible == true){
                        Navigator.pop(context);
                        // Фокус на таблицу (она уже видна)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Таблица уже открыта'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                      else{
                        setState(() => _isTableVisible = true);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.bar_chart,
                      color: _showStatistics ? Colors.blue : null,
                    ),
                    title: Text(
                      'Статистика',
                      style: TextStyle(
                        fontWeight: _showStatistics ? FontWeight.bold : null,
                        color: _showStatistics ? Colors.blue : null,
                      ),
                    ),
                    subtitle: const Text('Анализ числовых данных'),
                    trailing: _showStatistics
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _showStatistics = !_showStatistics;
                      });
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('О программе'),
                  subtitle: const Text('Версия 1.0.0'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }


    /// Показывает диалог с информацией о программе.
    void _showAboutDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('О программе Stat Flow'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Версия: 1.0.0'),
              SizedBox(height: 8),
              Text(
                'Приложение для загрузки и анализа CSV файлов. '
                'Позволяет просматривать данные в плавающей таблице '
                'и рассчитывать статистические показатели.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    /// Строит основное содержимое экрана в зависимости от состояния.
    ///
    /// Возможные состояния:
    /// - Загрузка: показывает индикатор прогресса
    /// - Нет данных: показывает пустое состояние с кнопкой загрузки
    /// - Данные загружены: показывает информацию и статистику
    Widget _buildMainContent() {
      if (_isLoading) {
        return Center(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text(
                  "Загрузка файла...",
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 20),

                LinearProgressIndicator(value: _progress),

                const SizedBox(height: 10),

                Text("${(_progress * 100).toStringAsFixed(1)} %"),
              ],
            ),
          ),
        );
      }

      if (_gridData == null) {
        return _buildEmptyState();
      }

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
            
                      const SizedBox(height: 20),
            
                      if (_showStatistics) ...[
                        HeatmapSection(
                          matrix: _dataset!.corr(),
                        ),
                        // SfCartesianChart(
                        //   primaryXAxis: CategoryAxis(),
                        //   primaryYAxis: NumericAxis(minimum: 0, interval: 10,),
                        //   tooltipBehavior: _tooltip,
                        //   series: <CartesianSeries<DataColumn, String>>[
                        //     BoxAndWhiskerSeries(
                        //       dataSource: _dataset!.columns,
                        //       xValueMapper: (DataColumn column, _) => column.name, 
                        //       yValueMapper: (DataColumn column, _) => column.values.where((v)))
                        //   ],
                        // )
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
        ]
      ); 
    }
  }