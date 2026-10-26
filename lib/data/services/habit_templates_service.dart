import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habit_template_model.dart';

class HabitTemplatesService {
  final FirebaseFirestore _firestore;

  HabitTemplatesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Referencia a las plantillas de AtomicLife
  CollectionReference<Map<String, dynamic>> get _templatesCollection =>
      _firestore.collection('habit_templates');

  // Consultar las plantillas activas
  Future<List<HabitTemplate>> getTemplates() async {
    try {
      final snapshot = await _templatesCollection
          .where('isActive', isEqualTo: true)
          .get();

      final templates = snapshot.docs
          .map((doc) => HabitTemplate.fromDocument(doc))
          .toList();

      // Ordenar alfabeticamente
      templates.sort((a, b) => a.name.compareTo(b.name));

      return templates;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw StateError('No se pudo interpretar el catalogo: $e');
    }
  }

  // Consultar una plantilla por su identificador
  Future<HabitTemplate?> getTemplateById(String templateId) async {
    final document = await _templatesCollection.doc(templateId).get();

    if (!document.exists) {
      return null;
    }

    return HabitTemplate.fromDocument(document);
  }

  // Escuchar cambios en el catalogo en tiempo real
  Stream<List<HabitTemplate>> watchTemplates() {
    return _templatesCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final templates = snapshot.docs
              .map((doc) => HabitTemplate.fromDocument(doc))
              .toList();

          templates.sort((a, b) => a.name.compareTo(b.name));

          return templates;
        });
  }
}
