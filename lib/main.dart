import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

// Controlador de autenticación
import 'modules/auth/controllers/auth_controller.dart';

// Pantallas de autenticación
import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/screens/recover_profile_screen.dart';

// Pantalla principal
import 'modules/home/screens/home_screen.dart';

// Servicio de notificaciones
import 'data/services/notification_service.dart';

Future<void> main() async {
  // Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================
  // 1. INICIALIZAR FIREBASE
  // ==========================================

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ==========================================
  // 2. INICIALIZAR NOTIFICACIONES LOCALES
  // ==========================================

  await NotificationService.instance.initialize();

  // ==========================================
  // 3. REGISTRAR CONTROLADOR GETX
  // ==========================================

  Get.put(AuthController(), permanent: true);

  // ==========================================
  // 4. INICIAR ATOMICLIFE
  // ==========================================

  runApp(const AtomicLifeApp());
}

// ==============================================
// APLICACIÓN PRINCIPAL
// ==============================================

class AtomicLifeApp extends StatelessWidget {
  const AtomicLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'AtomicLife',

      // ========================================
      // TEMA VISUAL
      // ========================================
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D64)),

        scaffoldBackgroundColor: const Color(0xFFF7FAF8),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // ========================================
      // GESTIÓN DE AUTENTICACIÓN CON GETX
      // ========================================
      home: Obx(() {
        final status = authController.authStatus.value;

        switch (status) {
          // ====================================
          // 1. VERIFICANDO AUTENTICACIÓN
          // ====================================

          case AuthStatus.checking:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          // ====================================
          // 2. USUARIO SIN SESIÓN
          // ====================================

          case AuthStatus.unauthenticated:
            return const LoginScreen();

          // ====================================
          // 3. USUARIO AUTENTICADO
          // ====================================

          case AuthStatus.authenticated:
            return const HomeScreen();

          // ====================================
          // 4. PERFIL INCOMPLETO
          // ====================================

          case AuthStatus.incompleteProfile:
            return const RecoverProfileScreen();

          // ====================================
          // 5. ERROR DE AUTENTICACIÓN
          // ====================================

          case AuthStatus.error:
            return Scaffold(
              appBar: AppBar(
                title: const Text('Verificación de cuenta'),
                centerTitle: true,
              ),

              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),

                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 70,
                            color: Colors.orange,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'No se pudo verificar tu cuenta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Mostrar error de autenticación
                          Obx(
                            () => Text(
                              authController.errorMessage.value,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Reintentar validación del perfil
                          Obx(
                            () => FilledButton.icon(
                              onPressed: authController.isLoading.value
                                  ? null
                                  : authController.retryValidation,

                              icon: const Icon(Icons.refresh),

                              label: const Text('Reintentar'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Cerrar sesión
                          Obx(
                            () => TextButton.icon(
                              onPressed: authController.isLoading.value
                                  ? null
                                  : () async {
                                      await authController.logout();
                                    },

                              icon: const Icon(Icons.logout),

                              label: const Text('Cerrar sesión'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
        }
      }),
    );
  }
}
