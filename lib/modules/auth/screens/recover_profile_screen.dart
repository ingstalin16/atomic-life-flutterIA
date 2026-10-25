import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class RecoverProfileScreen extends StatefulWidget {
  const RecoverProfileScreen({super.key});

  @override
  State<RecoverProfileScreen> createState() => _RecoverProfileScreenState();
}

class _RecoverProfileScreenState extends State<RecoverProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _recoverProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await _authController.recoverProfile(
      name: _nameController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authController.errorMessage.value),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }

    // Si la recuperacion fue exitosa,
    // GetX actualiza authStatus y main.dart
    // muestra automaticamente HomeScreen.
  }

  Future<void> _logout() async {
    final success = await _authController.logout();

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.errorMessage.value)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(title: const Text('Recuperar perfil'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 85,
                      color: Color(0xFF2E7D64),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Completa tu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF245A48),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Tu cuenta ya existe, pero necesitamos '
                      'completar tu informacion para comenzar '
                      'a construir tus habitos saludables.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    Obx(
                      () => Text(
                        'Cuenta: '
                        '${_authController.currentUser?.email ?? ""}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        hintText: 'Escribe tu nombre',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';

                        if (name.isEmpty) {
                          return 'Ingresa tu nombre';
                        }

                        if (name.length < 2) {
                          return 'Ingresa al menos 2 caracteres';
                        }

                        if (name.length > 80) {
                          return 'Maximo 80 caracteres';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    Obx(() {
                      final loading = _authController.isLoading.value;

                      return FilledButton.icon(
                        onPressed: loading ? null : _recoverProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D64),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(
                          loading
                              ? 'Recuperando perfil...'
                              : 'Recuperar mi perfil',
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    Obx(
                      () => TextButton.icon(
                        onPressed: _authController.isLoading.value
                            ? null
                            : _logout,
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
      ),
    );
  }
}
