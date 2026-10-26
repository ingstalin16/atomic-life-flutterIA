import 'package:flutter_test/flutter_test.dart';
import 'package:atomic_life/core/utils/habit_statistics_calculator.dart';

void main() {
  group('HabitStatisticsCalculator', () {
    // PRUEBA 1: Hábito cumplido diariamente
    test('Calcula correctamente una racha diaria', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 1),
        today: DateTime(2026, 10, 5),
        weekDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          '2026-10-01',
          '2026-10-02',
          '2026-10-03',
          '2026-10-04',
          '2026-10-05',
        },
      );

      expect(result.currentStreak, 5);
      expect(result.bestStreak, 5);
      expect(result.completedDays, 5);
      expect(result.scheduledDays, 5);
      expect(result.completionRate, 1.0);
    });

    // PRUEBA 2: Hábito lunes, miércoles y viernes
    test('Respeta los días programados', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 5),
        today: DateTime(2026, 10, 11),
        weekDays: [1, 3, 5],
        completedDates: {'2026-10-05', '2026-10-07', '2026-10-09'},
      );

      expect(result.currentStreak, 3);
      expect(result.bestStreak, 3);
      expect(result.completedDays, 3);
      expect(result.scheduledDays, 3);
      expect(result.completionRate, 1.0);
    });

    // PRUEBA 3: Un incumplimiento rompe la racha
    test('Interrumpe la racha cuando falta un día', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 1),
        today: DateTime(2026, 10, 5),
        weekDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          '2026-10-01',
          '2026-10-02',
          '2026-10-04',
          '2026-10-05',
        },
      );

      expect(result.currentStreak, 2);
      expect(result.bestStreak, 2);
      expect(result.completedDays, 4);
      expect(result.scheduledDays, 5);
      expect(result.completionRate, closeTo(0.8, 0.0001));
    });

    // PRUEBA 4: Los días libres no rompen la racha
    test('Ignora días no programados', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 9),
        today: DateTime(2026, 10, 12),
        weekDays: [1, 5],
        completedDates: {'2026-10-09', '2026-10-12'},
      );

      expect(result.currentStreak, 2);
      expect(result.bestStreak, 2);
      expect(result.completedDays, 2);
      expect(result.scheduledDays, 2);
    });

    // PRUEBA 5: Sin cumplimientos
    test('Devuelve cero cuando no hay cumplimientos', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 1),
        today: DateTime(2026, 10, 5),
        weekDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: <String>{},
      );

      expect(result.currentStreak, 0);
      expect(result.bestStreak, 0);
      expect(result.completedDays, 0);
      expect(result.scheduledDays, 5);
      expect(result.completionRate, 0.0);
    });

    // PRUEBA 6: Porcentaje de cumplimiento
    test('Calcula correctamente el porcentaje', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 1),
        today: DateTime(2026, 10, 4),
        weekDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {'2026-10-01', '2026-10-03', '2026-10-04'},
      );

      expect(result.scheduledDays, 4);
      expect(result.completedDays, 3);
      expect(result.completionRate, 0.75);
      expect(result.completionPercentage, 75.0);
    });

    // PRUEBA 7: Fecha de creación futura
    test('Devuelve estadísticas vacías para fechas futuras', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 10),
        today: DateTime(2026, 10, 5),
        weekDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: <String>{},
      );

      expect(result.currentStreak, 0);
      expect(result.bestStreak, 0);
      expect(result.completedDays, 0);
      expect(result.scheduledDays, 0);
      expect(result.completionRate, 0.0);
    });

    // PRUEBA 8: Hoy todavía está pendiente
    test('Conserva la racha mientras hoy está pendiente', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 1),
        today: DateTime(2026, 10, 5),
        weekDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          '2026-10-01',
          '2026-10-02',
          '2026-10-03',
          '2026-10-04',
        },
      );

      expect(result.currentStreak, 4);
      expect(result.bestStreak, 4);
      expect(result.completedDays, 4);
      expect(result.scheduledDays, 5);
      expect(result.completionRate, 0.8);
    });

    // PRUEBA 9: Días semanales inválidos
    test('Rechaza días de semana fuera de rango', () {
      expect(
        () => HabitStatisticsCalculator.calculate(
          createdAt: DateTime(2026, 10, 1),
          today: DateTime(2026, 10, 5),
          weekDays: [0, 8],
          completedDates: <String>{},
        ),
        throwsArgumentError,
      );
    });

    // PRUEBA 10: Hábito aún no programado en el intervalo
    test('Evita división entre cero', () {
      final result = HabitStatisticsCalculator.calculate(
        createdAt: DateTime(2026, 10, 5),
        today: DateTime(2026, 10, 5),
        weekDays: [2],
        completedDates: <String>{},
      );

      expect(result.scheduledDays, 0);
      expect(result.completedDays, 0);
      expect(result.currentStreak, 0);
      expect(result.completionRate, 0.0);
    });
  });
}
