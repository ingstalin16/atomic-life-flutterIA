import '../../data/models/habit_statistics_model.dart';

class HabitStatisticsCalculator {
  static HabitStatistics calculate({
    required DateTime createdAt,
    required DateTime today,
    required List<int> weekDays,
    required Set<String> completedDates,
  }) {
    if (weekDays.isEmpty || weekDays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Los días programados deben estar entre 1 y 7.');
    }

    final scheduledWeekDays = weekDays.toSet();

    DateTime onlyDate(DateTime value) {
      return DateTime(value.year, value.month, value.day);
    }

    String dateKey(DateTime date) {
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');

      return '$year-$month-$day';
    }

    final start = onlyDate(createdAt);
    final end = onlyDate(today);

    if (start.isAfter(end)) {
      return const HabitStatistics(
        currentStreak: 0,
        bestStreak: 0,
        completedDays: 0,
        scheduledDays: 0,
        completionRate: 0,
      );
    }

    int scheduledDays = 0;
    int completedDays = 0;
    int bestStreak = 0;
    int runningStreak = 0;

    final scheduledDates = <DateTime>[];

    for (
      var date = start;
      !date.isAfter(end);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      if (!scheduledWeekDays.contains(date.weekday)) {
        continue;
      }

      scheduledDates.add(date);
      scheduledDays++;

      if (completedDates.contains(dateKey(date))) {
        completedDays++;
        runningStreak++;

        if (runningStreak > bestStreak) {
          bestStreak = runningStreak;
        }
      } else {
        runningStreak = 0;
      }
    }

    int currentStreak = 0;
    var index = scheduledDates.length - 1;

    if (index >= 0) {
      final latest = scheduledDates[index];

      if (latest == end && !completedDates.contains(dateKey(latest))) {
        index--;
      }
    }

    while (index >= 0) {
      if (!completedDates.contains(dateKey(scheduledDates[index]))) {
        break;
      }

      currentStreak++;
      index--;
    }

    final rate = scheduledDays == 0 ? 0.0 : completedDays / scheduledDays;

    return HabitStatistics(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completedDays: completedDays,
      scheduledDays: scheduledDays,
      completionRate: rate,
    );
  }
}
