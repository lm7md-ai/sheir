/// تقييمات استذكار الحفظ المتباعد الأربعة
enum SrsRating {
  again, // نسيت: إعادة الفحص فوراً
  hard,  // صعب: استذكار بمشقة
  good,  // جيد: استذكار طبيعي سلس
  easy,  // سهل: استذكار فوري راسخ
}

/// حالة بطاقة الحفظ والاستذكار لبيت أو مقطع شعري
class SrsCardState {
  final String cardId;
  final int verseId;
  final double stability;      // الاستقرار (S)
  final double difficulty;     // الصعوبة (D)
  final int repetitions;       // عدد التكرارات السابقة
  final int intervalDays;      // الفاصل الزمني بالأيام حتى المراجعة القادمة
  final DateTime lastReviewed; // تاريخ آخر مراجعة
  final DateTime nextDue;      // موعد الاستحقاق القادم

  const SrsCardState({
    required this.cardId,
    required this.verseId,
    required this.stability,
    required this.difficulty,
    required this.repetitions,
    required this.intervalDays,
    required this.lastReviewed,
    required this.nextDue,
  });

  factory SrsCardState.initial(int verseId) {
    final now = DateTime.now();
    return SrsCardState(
      cardId: 'card_$verseId',
      verseId: verseId,
      stability: 1.0,
      difficulty: 5.0,
      repetitions: 0,
      intervalDays: 0,
      lastReviewed: now,
      nextDue: now,
    );
  }

  SrsCardState copyWith({
    double? stability,
    double? difficulty,
    int? repetitions,
    int? intervalDays,
    DateTime? lastReviewed,
    DateTime? nextDue,
  }) {
    return SrsCardState(
      cardId: cardId,
      verseId: verseId,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextDue: nextDue ?? this.nextDue,
    );
  }
}

/// محرك التكرار المتباعد الشعري (FSRS / SM-2 Poetic Scheduler)
class SpacedRepetitionEngine {
  SpacedRepetitionEngine._();

  /// حساب الحالة التالية بعد تقييم المستخدم للبيت الشعري
  static SrsCardState calculateNextState(
    SrsCardState current,
    SrsRating rating, {
    DateTime? reviewTime,
  }) {
    final now = reviewTime ?? DateTime.now();
    double newStability = current.stability;
    double newDifficulty = current.difficulty;
    int newReps = current.repetitions;
    int nextInterval;

    switch (rating) {
      case SrsRating.again:
        // نسي البيت بالكامل: تصفير الاستقرار وتحديد مراجعة في الجلسة ذاتها (10 دقائق)
        newStability = 0.5;
        newDifficulty = (newDifficulty + 1.2).clamp(1.0, 10.0);
        newReps = 0;
        nextInterval = 0; // يستحق الآن
        break;

      case SrsRating.hard:
        // استذكر بصعوبة
        newStability = newStability * 1.2;
        newDifficulty = (newDifficulty + 0.5).clamp(1.0, 10.0);
        newReps += 1;
        nextInterval = newReps == 1 ? 1 : (current.intervalDays * 1.2).round().clamp(1, 180);
        break;

      case SrsRating.good:
        // استذكار طبيعي متزن
        newStability = newStability * 2.2;
        newDifficulty = (newDifficulty - 0.2).clamp(1.0, 10.0);
        newReps += 1;
        nextInterval = newReps == 1 ? 2 : (current.intervalDays * 2.4).round().clamp(2, 365);
        break;

      case SrsRating.easy:
        // استذكار راسخ فوري
        newStability = newStability * 3.5;
        newDifficulty = (newDifficulty - 0.8).clamp(1.0, 10.0);
        newReps += 1;
        nextInterval = newReps == 1 ? 4 : (current.intervalDays * 3.5).round().clamp(4, 730);
        break;
    }

    final nextDueDate = nextInterval == 0
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(days: nextInterval));

    return current.copyWith(
      stability: double.parse(newStability.toStringAsFixed(2)),
      difficulty: double.parse(newDifficulty.toStringAsFixed(2)),
      repetitions: newReps,
      intervalDays: nextInterval,
      lastReviewed: now,
      nextDue: nextDueDate,
    );
  }

  /// النص العربي التقديري للفاصل الزمني القادم
  static String getIntervalLabel(SrsRating rating, SrsCardState current) {
    switch (rating) {
      case SrsRating.again:
        return 'بعد ١٠ دقائق';
      case SrsRating.hard:
        return current.repetitions == 0 ? 'غداً' : 'بعد ${((current.intervalDays * 1.2).round()).clamp(1, 100)} يوم';
      case SrsRating.good:
        return current.repetitions == 0 ? 'بعد يومين' : 'بعد ${((current.intervalDays * 2.4).round()).clamp(2, 200)} يوم';
      case SrsRating.easy:
        return current.repetitions == 0 ? 'بعد ٤ أيام' : 'بعد ${((current.intervalDays * 3.5).round()).clamp(4, 365)} يوم';
    }
  }
}
