import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../data/models/habit_completion_model.dart';
import '../../../data/repositories/habit_completion_repository.dart';

enum CalendarStatus { loading, success, empty, error }

class HabitCalendarController extends GetxController {
  HabitCalendarController({
    required this.habitId,
    required this.habitName,
    HabitCompletionRepository? repository,
  }) : _repository = repository ?? HabitCompletionRepository();

  final String habitId;
  final String habitName;

  final HabitCompletionRepository _repository;

  // Mes que el usuario está consultando
  final Rx<DateTime> selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;

  // Días registrados como completados
  final RxSet<String> completedDates = <String>{}.obs;

  final Rx<CalendarStatus> status = CalendarStatus.loading.obs;

  final RxString errorMessage = ''.obs;

  int _loadVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadMonth();
  }

  // Consultar los cumplimientos del mes seleccionado
  Future<void> loadMonth() async {
    final version = ++_loadVersion;

    status.value = CalendarStatus.loading;
    errorMessage.value = '';

    try {
      final month = selectedMonth.value;

      final firstDay = DateTime(month.year, month.month, 1);

      final lastDay = DateTime(month.year, month.month + 1, 0);

      final history = await _repository.getHistoryBetween(
        habitId: habitId,
        start: firstDay,
        end: lastDay,
      );

      if (isClosed || version != _loadVersion) return;

      completedDates.assignAll(
        history
            .where((record) => record.completed)
            .map((record) => record.date),
      );

      status.value = completedDates.isEmpty
          ? CalendarStatus.empty
          : CalendarStatus.success;
    } catch (error) {
      if (isClosed || version != _loadVersion) return;

      errorMessage.value = _friendlyError(error);
      status.value = CalendarStatus.error;
    }
  }

  // Consultar el mes anterior
  Future<void> previousMonth() async {
    final month = selectedMonth.value;

    selectedMonth.value = DateTime(month.year, month.month - 1);

    await loadMonth();
  }

  // Consultar el mes siguiente, sin superar el actual
  Future<void> nextMonth() async {
    final month = selectedMonth.value;
    final next = DateTime(month.year, month.month + 1);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    if (next.isAfter(currentMonth)) return;

    selectedMonth.value = next;

    await loadMonth();
  }

  // Volver al mes actual
  Future<void> goToCurrentMonth() async {
    final now = DateTime.now();

    selectedMonth.value = DateTime(now.year, now.month);

    await loadMonth();
  }

  // Comprobar si una fecha está completada
  bool isCompleted(DateTime date) {
    final dateKey = HabitCompletion.dateKey(date);

    return completedDates.contains(dateKey);
  }

  // Total de días completados del mes
  int get completedDays => completedDates.length;

  // Cantidad de días del mes seleccionado
  int get daysInMonth {
    final month = selectedMonth.value;

    return DateTime(month.year, month.month + 1, 0).day;
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return 'Debes iniciar sesión para consultar tu historial.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para consultar '
              'el historial de este hábito.';
        case 'unavailable':
          return 'No se pudo conectar con Firebase.';
        default:
          return 'Error de Firebase: ${error.code}';
      }
    }

    return 'No fue posible cargar el calendario.';
  }
}
