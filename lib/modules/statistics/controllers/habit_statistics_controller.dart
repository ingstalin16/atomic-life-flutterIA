import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/utils/habit_statistics_calculator.dart';
import '../../../data/models/habit_statistics_model.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/habit_completion_repository.dart';

enum StatisticsStatus { loading, success, error }

class HabitStatisticsController extends GetxController {
  HabitStatisticsController({
    required this.habitId,
    HabitRepository? habitRepository,
    HabitCompletionRepository? completionRepository,
  }) : _habitRepository = habitRepository ?? HabitRepository(),
       _completionRepository =
           completionRepository ?? HabitCompletionRepository();

  final String habitId;

  final HabitRepository _habitRepository;
  final HabitCompletionRepository _completionRepository;

  // Información del hábito seleccionado
  final RxString habitName = ''.obs;
  final RxString habitCategory = ''.obs;

  // Resultado del cálculo de estadísticas
  final Rxn<HabitStatistics> statistics = Rxn<HabitStatistics>();

  // Estado de la consulta
  final Rx<StatisticsStatus> status = StatisticsStatus.loading.obs;

  final RxString errorMessage = ''.obs;

  // Evita que una consulta antigua sobrescriba otra nueva
  int _loadVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadStatistics();
  }

  // Consultar el hábito y sus cumplimientos
  Future<void> loadStatistics() async {
    final version = ++_loadVersion;

    status.value = StatisticsStatus.loading;
    errorMessage.value = '';

    try {
      // 1. Obtener los datos del hábito
      final habit = await _habitRepository.getHabitById(habitId);

      if (habit == null) {
        throw StateError('El hábito solicitado no existe.');
      }

      // 2. Obtener la fecha de creación
      final createdAtValue = habit['createdAt'];

      if (createdAtValue is! Timestamp) {
        throw StateError('El hábito no tiene una fecha de creación válida.');
      }

      final createdAt = createdAtValue.toDate();

      // 3. Obtener los días programados
      final weekDaysValue = habit['weekDays'];

      if (weekDaysValue is! List) {
        throw StateError('El hábito no tiene días programados válidos.');
      }

      final weekDays = weekDaysValue.whereType<int>().toList();

      // 4. Obtener el historial desde Firestore
      final history = await _completionRepository.getHistory(habitId: habitId);

      // 5. Construir el conjunto de fechas completadas
      final completedDates = history
          .where((record) => record.completed)
          .map((record) => record.date)
          .toSet();

      // 6. Calcular los indicadores
      final result = HabitStatisticsCalculator.calculate(
        createdAt: createdAt,
        today: DateTime.now(),
        weekDays: weekDays,
        completedDates: completedDates,
      );

      if (isClosed || version != _loadVersion) return;

      // 7. Publicar los resultados mediante GetX
      habitName.value = habit['name'] as String? ?? 'Sin nombre';

      habitCategory.value = habit['category'] as String? ?? '';

      statistics.value = result;
      status.value = StatisticsStatus.success;
    } catch (error) {
      if (isClosed || version != _loadVersion) return;

      statistics.value = null;
      errorMessage.value = _friendlyError(error);
      status.value = StatisticsStatus.error;
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para consultar '
              'las estadísticas de este hábito.';

        case 'unavailable':
          return 'No se pudo conectar con Firebase. '
              'Comprueba tu conexión a Internet.';

        case 'unauthenticated':
          return 'Debes iniciar sesión para consultar '
              'tus estadísticas.';

        case 'not-found':
          return 'El hábito solicitado no existe.';

        default:
          return 'Error de Firebase: ${error.code}';
      }
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'No fue posible calcular las estadísticas. '
        'Intenta nuevamente.';
  }
}
