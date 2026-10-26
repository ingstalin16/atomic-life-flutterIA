//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/habit_completion_repository.dart';

enum TrackingStatus { loading, success, empty, error }

class HabitTrackingController extends GetxController {
  HabitTrackingController({
    HabitRepository? habitRepository,
    HabitCompletionRepository? completionRepository,
  }) : _habitRepository = habitRepository ?? HabitRepository(),
       _completionRepository =
           completionRepository ?? HabitCompletionRepository();

  final HabitRepository _habitRepository;
  final HabitCompletionRepository _completionRepository;

  // Fecha que estamos consultando.
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Habitos activos programados para ese dia.
  final RxList<Map<String, dynamic>> todayHabits = <Map<String, dynamic>>[].obs;

  // Estado de cumplimiento por identificador.
  final RxMap<String, bool> completions = <String, bool>{}.obs;

  // Identificador del habito que se esta guardando.
  final RxString processingHabitId = ''.obs;

  final Rx<TrackingStatus> status = TrackingStatus.loading.obs;

  final RxString errorMessage = ''.obs;

  // Evita aplicar resultados antiguos de consultas.
  int _loadVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadToday();
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  // Cargar los habitos programados para hoy.
  Future<void> loadToday() async {
    final version = ++_loadVersion;

    selectedDate.value = DateTime.now();
    status.value = TrackingStatus.loading;
    errorMessage.value = '';

    try {
      final date = selectedDate.value;
      final weekday = date.weekday;

      final allHabits = await _habitRepository.getMyHabits();

      // Solo habitos activos y programados para hoy.
      final scheduled = allHabits.where((habit) {
        final active = habit['isActive'] == true;

        final days =
            (habit['weekDays'] as List<dynamic>?)?.whereType<int>().toList() ??
            <int>[];

        return active && days.contains(weekday);
      }).toList();

      scheduled.sort((a, b) {
        final timeA = a['scheduledTime'] as String? ?? '';
        final timeB = b['scheduledTime'] as String? ?? '';

        return timeA.compareTo(timeB);
      });

      // Consultar cumplimientos de cada habito.
      final results = await Future.wait(
        scheduled.map((habit) async {
          final habitId = habit['id'] as String;

          final completed = await _completionRepository.isCompleted(
            habitId: habitId,
            date: date,
          );

          return MapEntry(habitId, completed);
        }),
      );

      if (isClosed || version != _loadVersion) {
        return;
      }

      todayHabits.assignAll(scheduled);

      completions.assignAll(Map<String, bool>.fromEntries(results));

      status.value = scheduled.isEmpty
          ? TrackingStatus.empty
          : TrackingStatus.success;
    } catch (error) {
      if (isClosed || version != _loadVersion) {
        return;
      }

      errorMessage.value = _friendlyError(error);
      status.value = TrackingStatus.error;
    }
  }

  // Saber si un habito esta completado.
  bool isHabitCompleted(String habitId) {
    return completions[habitId] == true;
  }

  // Marcar o desmarcar un cumplimiento.
  Future<bool> toggleCompletion(String habitId) async {
    if (status.value != TrackingStatus.success ||
        processingHabitId.value.isNotEmpty) {
      return false;
    }

    if (!todayHabits.any((habit) => habit['id'] == habitId)) {
      errorMessage.value = 'El habito no esta programado para hoy.';
      return false;
    }

    processingHabitId.value = habitId;
    errorMessage.value = '';

    // Si cambia el dia durante la operacion,
    // recargaremos la informacion actual.
    final operationDate = selectedDate.value;
    final originalDateKey = _dateKey(operationDate);

    try {
      final wasCompleted = isHabitCompleted(habitId);

      if (wasCompleted) {
        await _completionRepository.unmarkCompleted(
          habitId: habitId,
          date: operationDate,
        );
      } else {
        await _completionRepository.markCompleted(
          habitId: habitId,
          date: operationDate,
        );
      }

      if (isClosed) return false;

      if (originalDateKey != _dateKey(DateTime.now())) {
        await loadToday();
        return true;
      }

      completions[habitId] = !wasCompleted;
      return true;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = _friendlyError(error);
      }

      return false;
    } finally {
      if (!isClosed) {
        processingHabitId.value = '';
      }
    }
  }

  // Cantidad de habitos programados hoy.
  int get totalToday => todayHabits.length;

  // Cantidad de habitos completados hoy.
  int get completedToday {
    return todayHabits.where((habit) {
      final id = habit['id'] as String?;
      return id != null && completions[id] == true;
    }).length;
  }

  // Porcentaje de cumplimiento del dia.
  double get progress {
    final total = totalToday;

    if (total == 0) return 0;

    return completedToday / total;
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return 'Inicia sesion para consultar tus habitos.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permiso para registrar '
              'este cumplimiento. Revisa las reglas '
              'de Firestore.';

        case 'unavailable':
          return 'No se pudo conectar con Firebase. '
              'Comprueba tu conexion.';

        case 'not-found':
          return 'No se encontro el registro solicitado.';

        default:
          return 'Error de Firebase: ${error.code}';
      }
    }

    return 'No se pudo completar la operacion. '
        'Intenta nuevamente.';
  }
}
