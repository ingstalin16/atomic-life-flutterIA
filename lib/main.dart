import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/screens/recover_profile_screen.dart';
import 'modules/home/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar controlador de autenticacion con GetX
  Get.put(AuthController(), permanent: true);

  // Iniciar AtomicLife
  runApp(const AtomicLifeApp());
}

class AtomicLifeApp extends StatelessWidget {
  const AtomicLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AtomicLife',

      // Tema visual de la aplicacion
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D64)),
        scaffoldBackgroundColor: const Color(0xFFF7FAF8),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Gestion centralizada del acceso con GetX
      home: Obx(() {
        final status = authController.authStatus.value;

        switch (status) {
          // 1. Verificando autenticacion
          case AuthStatus.checking:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          // 2. Usuario sin sesion
          case AuthStatus.unauthenticated:
            return const LoginScreen();

          // 3. Usuario con perfil validado
          case AuthStatus.authenticated:
            return const HomeScreen();

          // 4. Perfil incompleto en Firestore
          case AuthStatus.incompleteProfile:
            return const RecoverProfileScreen();

          // 5. Error de autenticacion o verificacion
          case AuthStatus.error:
            return Scaffold(
              appBar: AppBar(
                title: const Text('Verificacion de cuenta'),
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

                          Obx(
                            () => Text(
                              authController.errorMessage.value,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Reintentar la validacion del perfil
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

                          // Cerrar sesion
                          Obx(
                            () => TextButton.icon(
                              onPressed: authController.isLoading.value
                                  ? null
                                  : () async {
                                      await authController.logout();
                                    },
                              icon: const Icon(Icons.logout),
                              label: const Text('Cerrar sesion'),
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
