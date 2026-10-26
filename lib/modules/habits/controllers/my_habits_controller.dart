import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/repositories/habit_repository.dart';

enum MyHabitsStatus { loading, success, empty, error }

class MyHabitsController extends GetxController {
  MyHabitsController({HabitRepository? repository})
    : _repository = repository ?? HabitRepository();

  final HabitRepository _repository;

  // Lista de hábitos personales
  final RxList<Map<String, dynamic>> habits = <Map<String, dynamic>>[].obs;

  // Estado de consulta
  final Rx<MyHabitsStatus> status = MyHabitsStatus.loading.obs;

  // Procesamiento de operaciones
  final RxBool isProcessing = false.obs;

  // Mensaje de error
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHabits();
  }

  // Obtener hábitos desde Firestore
  Future<void> loadHabits() async {
    status.value = MyHabitsStatus.loading;
    errorMessage.value = '';

    try {
      final result = await _repository.getMyHabits();

      if (isClosed) return;

      habits.assignAll(result);

      status.value = result.isEmpty
          ? MyHabitsStatus.empty
          : MyHabitsStatus.success;
    } catch (error) {
      if (isClosed) return;

      errorMessage.value = _friendlyError(error);
      status.value = MyHabitsStatus.error;
    }
  }

  // Pausar o reactivar un hábito
  Future<bool> changeHabitStatus({
    required String habitId,
    required bool isActive,
  }) async {
    if (isProcessing.value) return false;

    isProcessing.value = true;
    errorMessage.value = '';

    try {
      await _repository.setHabitActive(habitId: habitId, isActive: isActive);

      await loadHabits();

      return status.value != MyHabitsStatus.error;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = _friendlyError(error);
      }
      return false;
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  // Eliminar un hábito
  Future<bool> removeHabit(String habitId) async {
    if (isProcessing.value) return false;

    isProcessing.value = true;
    errorMessage.value = '';

    try {
      await _repository.deleteHabit(habitId);

      await loadHabits();

      return status.value != MyHabitsStatus.error;
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = _friendlyError(error);
      }
      return false;
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  // Refrescar después de editar
  Future<void> refreshAfterEdit() async {
    await loadHabits();
  }

  // Interpretación de errores
  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      if (error.code == 'unauthenticated') {
        return 'Debes iniciar sesión para gestionar tus hábitos.';
      }
      return 'Error de autenticación: ${error.code}';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para modificar este hábito.';

        case 'unavailable':
          return 'No se pudo conectar con Firebase.';

        case 'not-found':
          return 'El hábito ya no existe.';

        default:
          return 'Error de Firebase: ${error.code}';
      }
    }

    return 'Ocurrió un error al gestionar el hábito.';
  }
}
