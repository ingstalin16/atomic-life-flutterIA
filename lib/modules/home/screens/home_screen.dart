import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/notification_service.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../habits/screens/habit_catalog_screen.dart';
import '../../habits/screens/habit_form_screen.dart';
import '../../habits/screens/my_habits_screen.dart';
import '../../tracking/screens/habit_tracking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AtomicLife',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(context, authController),
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  // =====================================
                  // LOGO PRINCIPAL
                  // =====================================

                  const Icon(Icons.spa, size: 85, color: Color(0xFF2E7D64)),

                  const SizedBox(height: 24),

                  // =====================================
                  // MENSAJE DE BIENVENIDA
                  // =====================================
                  const Text(
                    '¡Bienvenido a AtomicLife!',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // =====================================
                  // CORREO DEL USUARIO AUTENTICADO
                  // =====================================
                  Obx(
                    () => Text(
                      authController.currentUser?.email ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =====================================
                  // FRASE MOTIVACIONAL
                  // =====================================
                  const Text(
                    'Tu transformación comienza con '
                    'un pequeño hábito cada día.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 36),

                  // =====================================
                  // OPCIÓN 1: EXPLORAR HÁBITOS
                  // =====================================
                  FilledButton.icon(
                    onPressed: () {
                      Get.to(() => const HabitCatalogScreen());
                    },

                    icon: const Icon(Icons.explore_outlined),

                    label: const Text(
                      'Explorar hábitos saludables',
                      textAlign: TextAlign.center,
                    ),

                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =====================================
                  // OPCIÓN 2: CREAR HÁBITO
                  // =====================================
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.to(() => const HabitFormScreen());
                    },

                    icon: const Icon(Icons.add_circle_outline),

                    label: const Text(
                      'Crear mi propio hábito',
                      textAlign: TextAlign.center,
                    ),

                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =====================================
                  // OPCIÓN 3: MIS HÁBITOS
                  // =====================================
                  FilledButton.icon(
                    onPressed: () {
                      Get.to(() => const MyHabitsScreen());
                    },

                    icon: const Icon(Icons.checklist),

                    label: const Text(
                      'Mis hábitos',
                      textAlign: TextAlign.center,
                    ),

                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =====================================
                  // OPCIÓN 4: SEGUIMIENTO DIARIO
                  // =====================================
                  FilledButton.icon(
                    onPressed: () {
                      Get.to(() => const HabitTrackingScreen());
                    },

                    icon: const Icon(Icons.today_outlined),

                    label: const Text(
                      'Mis hábitos de hoy',
                      textAlign: TextAlign.center,
                    ),

                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D64),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =====================================
                  // OPCIÓN 5: PRUEBA DE NOTIFICACIONES
                  // =====================================
                  OutlinedButton.icon(
                    onPressed: () => _testNotification(context),

                    icon: const Icon(Icons.notifications_active_outlined),

                    label: const Text(
                      'Probar notificaciones',
                      textAlign: TextAlign.center,
                    ),

                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =====================================
                  // MENSAJE INFERIOR
                  // =====================================
                  const Text(
                    'Construye buenos hábitos, '
                    'un pequeño paso a la vez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // PROBAR NOTIFICACIONES LOCALES
  // =====================================================

  Future<void> _testNotification(BuildContext context) async {
    try {
      final notificationService = NotificationService.instance;

      // Inicializar servicio si fuera necesario.
      await notificationService.initialize();

      // Solicitar permisos de Android.
      final permitted = await notificationService.requestPermission();

      if (!context.mounted) return;

      // Comprobar autorización.
      if (!permitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Las notificaciones no están autorizadas. '
              'Revisa los permisos de AtomicLife '
              'en la configuración de Android.',
            ),
          ),
        );
        return;
      }

      // Enviar notificación de prueba inmediata.
      await notificationService.showTestNotification();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación de prueba enviada correctamente.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar la notificación: $error'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // =====================================================
  // CONFIRMAR CIERRE DE SESIÓN
  // =====================================================

  Future<void> _confirmLogout(
    BuildContext context,
    AuthController controller,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),

        content: const Text('¿Deseas salir de tu cuenta de AtomicLife?'),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancelar'),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await controller.logout();

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(controller.errorMessage.value)));
    }
  }
}
