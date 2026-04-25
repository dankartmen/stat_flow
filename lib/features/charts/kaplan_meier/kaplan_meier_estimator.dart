/// {@template kaplan_meier_point}
/// Точка кривой выживаемости Каплан-Мейера.
/// 
/// Представляет состояние в определённый момент времени:
/// - Время события (или последнего цензурирования)
/// - Доля выживших (вероятность выживания)
/// - Количество пациентов под риском до этого момента
/// - Количество событий (смертей/отказов) в этот момент
/// - Количество цензурированных наблюдений
/// {@endtemplate}
class KaplanMeierPoint {
  /// Момент времени (обычно дни, месяцы, годы).
  final double time;
  
  /// Вероятность выживания (кумулятивная выживаемость) к данному моменту.
  final double survival;
  
  /// Количество пациентов, находившихся под риском непосредственно перед данным моментом.
  final int atRisk;
  
  /// Количество событий (смертей/отказов), произошедших в данный момент.
  final int events;
  
  /// Количество цензурированных наблюдений в данный момент.
  final int censored;

  /// {@macro kaplan_meier_point}
  KaplanMeierPoint({
    required this.time,
    required this.survival,
    required this.atRisk,
    required this.events,
    required this.censored,
  });
}

/// {@template kaplan_meier_result}
/// Результат оценки кривой выживаемости для одной группы.
/// 
/// Содержит:
/// - Название группы (отображается в легенде)
/// - Список точек кривой
/// - Медианное время выживаемости (время, когда выживаемость падает до 50%)
/// - Общую статистику (всего пациентов, событий, цензурированных)
/// {@endtemplate}
class KaplanMeierResult {
  /// Название группы (отображается в легенде).
  final String groupName;
  
  /// Список точек кривой (отсортирован по времени).
  final List<KaplanMeierPoint> points;
  
  /// Медианное время выживаемости (время, когда выживаемость становится ≤ 0.5).
  /// Если выживаемость не падает ниже 0.5, возвращается последнее время.
  final double medianSurvivalTime;
  
  /// Общее количество пациентов в группе (изначально под риском).
  final int totalPatients;
  
  /// Общее количество событий (смертей/отказов) в группе.
  final int totalEvents;
  
  /// Общее количество цензурированных наблюдений.
  final int totalCensored;

  /// {@macro kaplan_meier_result}
  KaplanMeierResult({
    required this.groupName,
    required this.points,
    required this.medianSurvivalTime,
    required this.totalPatients,
    required this.totalEvents,
    required this.totalCensored,
  });
}

/// {@template kaplan_meier_estimator}
/// Оценщик кривых выживаемости методом Каплан-Мейера.
/// 
/// Реализует алгоритм построения ступенчатой кривой выживаемости:
/// - Сортировка данных по времени
/// - Расчёт накопленной вероятности выживания по формуле:
///   S(t) = ∏ (1 - d_i / n_i), где d_i — события в момент t, n_i — под риском
/// - Отслеживание медианного времени выживаемости
/// - Подсчёт статистики по группе
/// 
/// Также предоставляет упрощённую версию лог-ранк теста для сравнения двух групп.
/// {@endtemplate}
class KaplanMeierEstimator {
  /// Вычисляет кривую выживаемости для одной группы.
  ///
  /// Принимает:
  /// - [times] — список времён наблюдения для каждого пациента.
  /// - [events] — список бинарных индикаторов события (1 — событие, 0 — цензура).
  /// - [groupName] — название группы (по умолчанию "Все пациенты").
  ///
  /// Возвращает:
  /// - [KaplanMeierResult] с рассчитанной кривой.
  ///
  /// Исключение:
  /// - бросает [ArgumentError], если списки пусты или их длины не совпадают.
  static KaplanMeierResult estimate({
    required List<double> times,
    required List<int> events,
    String groupName = 'Все пациенты',
  }) {
    if (times.isEmpty || events.isEmpty || times.length != events.length) {
      throw ArgumentError('times и events должны быть одинаковой длины и не пустыми');
    }

    // Сортировка по времени
    final indices = List.generate(times.length, (i) => i);
    indices.sort((a, b) => times[a].compareTo(times[b]));

    final sortedTimes = indices.map((i) => times[i]).toList();
    final sortedEvents = indices.map((i) => events[i]).toList();

    final points = <KaplanMeierPoint>[];
    int atRisk = times.length;
    double survival = 1.0;
    int totalEvents = 0;
    int totalCensored = 0;
    double? medianTime;

    int i = 0;
    while (i < sortedTimes.length) {
      final currentTime = sortedTimes[i];
      int eventsAtTime = 0;
      int censoredAtTime = 0;

      // Агрегируем все наблюдения в один момент времени
      while (i < sortedTimes.length && sortedTimes[i] == currentTime) {
        if (sortedEvents[i] == 1) {
          eventsAtTime++;
        } else {
          censoredAtTime++;
        }
        i++;
      }

      totalEvents += eventsAtTime;
      totalCensored += censoredAtTime;

      // Обновляем вероятность выживания
      if (eventsAtTime > 0) {
        survival *= (1 - eventsAtTime / atRisk);
      }

      points.add(KaplanMeierPoint(
        time: currentTime,
        survival: survival,
        atRisk: atRisk,
        events: eventsAtTime,
        censored: censoredAtTime,
      ));

      // Отслеживаем медиану (первый момент, когда survival <= 0.5)
      if (medianTime == null && survival <= 0.5) {
        medianTime = currentTime;
      }

      // Уменьшаем число пациентов под риском
      atRisk -= (eventsAtTime + censoredAtTime);
    }

    return KaplanMeierResult(
      groupName: groupName,
      points: points,
      medianSurvivalTime: medianTime ?? sortedTimes.last,
      totalPatients: times.length,
      totalEvents: totalEvents,
      totalCensored: totalCensored,
    );
  }

  /// Сравнивает две кривые с помощью лог-ранк теста (упрощённая версия).
  ///
  /// Принимает:
  /// - [group1] — результат для первой группы.
  /// - [group2] — результат для второй группы.
  ///
  /// Возвращает:
  /// - значение статистики χ² (хи-квадрат). Большие значения указывают на значимые различия.
  /// 
  /// Примечание:
  /// - Это упрощённая реализация, которая не учитывает временные точки.
  /// - В реальном приложении рекомендуется использовать полноценный статистический пакет.
  static double logRankTest(KaplanMeierResult group1, KaplanMeierResult group2) {
    final o1 = group1.totalEvents.toDouble();
    final o2 = group2.totalEvents.toDouble();
    final n1 = group1.totalPatients.toDouble();
    final n2 = group2.totalPatients.toDouble();
    final totalEvents = o1 + o2;
    final totalPatients = n1 + n2;

    final e1 = totalEvents * n1 / totalPatients;
    final e2 = totalEvents * n2 / totalPatients;

    final chi2 = (o1 - e1) * (o1 - e1) / e1 + (o2 - e2) * (o2 - e2) / e2;
    
    // Для получения p-value нужно использовать распределение χ² с 1 степенью свободы
    return chi2;
  }
}