import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/habit_template_model.dart';
import '../../../data/services/habit_templates_service.dart';

// Estados de carga del catalogo
enum CatalogStatus { loading, success, empty, error }

class HabitTemplatesController extends GetxController {
  final HabitTemplatesService _service;

  HabitTemplatesController({HabitTemplatesService? service})
    : _service = service ?? HabitTemplatesService();

  // Lista de plantillas obtenidas de Firebase
  final RxList<HabitTemplate> templates = <HabitTemplate>[].obs;

  // Estado del catalogo
  final Rx<CatalogStatus> status = CatalogStatus.loading.obs;

  // Mensaje de error
  final RxString errorMessage = ''.obs;

  // Filtros del catalogo
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'Todas'.obs;

  // Plantilla seleccionada
  final Rxn<HabitTemplate> selectedTemplate = Rxn<HabitTemplate>();

  @override
  void onInit() {
    super.onInit();
    loadTemplates();
  }

  // Cargar plantillas desde Firestore
  Future<void> loadTemplates() async {
    status.value = CatalogStatus.loading;
    errorMessage.value = '';

    try {
      final result = await _service.getTemplates();

      templates.assignAll(result);

      status.value = result.isEmpty
          ? CatalogStatus.empty
          : CatalogStatus.success;
    } on FirebaseException catch (e) {
      errorMessage.value = _firebaseErrorMessage(e);
      status.value = CatalogStatus.error;
    } catch (_) {
      errorMessage.value = 'No se pudo cargar el catalogo de habitos.';
      status.value = CatalogStatus.error;
    }
  }

  // Categorias disponibles
  List<String> get categories {
    final values = templates.map((habit) => habit.category).toSet().toList()
      ..sort();

    return ['Todas', ...values];
  }

  // Plantillas filtradas
  List<HabitTemplate> get filteredTemplates {
    final query = searchQuery.value.trim().toLowerCase();
    final category = selectedCategory.value;

    return templates.where((habit) {
      final matchesCategory = category == 'Todas' || habit.category == category;

      final matchesSearch =
          query.isEmpty ||
          habit.name.toLowerCase().contains(query) ||
          habit.category.toLowerCase().contains(query) ||
          habit.microAction.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Actualizar busqueda
  void updateSearch(String value) {
    searchQuery.value = value;
  }

  // Filtrar categoria
  void updateCategory(String value) {
    selectedCategory.value = value;
  }

  // Seleccionar un habito para consultar sus detalles
  void selectTemplate(HabitTemplate habit) {
    selectedTemplate.value = habit;
  }

  // Limpiar seleccion
  void clearSelection() {
    selectedTemplate.value = null;
  }

  // Traducir errores comunes de Firestore
  String _firebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para consultar '
            'el catalogo de habitos.';

      case 'unavailable':
        return 'No hay conexion con Firebase. '
            'Comprueba tu acceso a Internet.';

      case 'unauthenticated':
        return 'Debes iniciar sesion para '
            'consultar los habitos.';

      case 'deadline-exceeded':
        return 'La consulta demoro demasiado. '
            'Intenta nuevamente.';

      default:
        return 'Error al consultar Firestore: ${e.code}';
    }
  }
}
