class HabitStatistics {
  final int currentStreak;
  final int bestStreak;
  final int completedDays;
  final int scheduledDays;
  final double completionRate;

  const HabitStatistics({
    required this.currentStreak,
    required this.bestStreak,
    required this.completedDays,
    required this.scheduledDays,
    required this.completionRate,
  });

  double get completionPercentage => completionRate * 100;

  bool get hasProgress => completedDays > 0;
}
