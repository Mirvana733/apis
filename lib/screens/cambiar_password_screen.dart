import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/fondo_lulilu.dart';

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final actualController = TextEditingController();
  final nuevaController = TextEditingController();
  final confirmarController = TextEditingController();

  bool mostrarActual = false;
  bool mostrarNueva = false;
  bool cambiando = false;

  @override
  void dispose() {
    actualController.dispose();
    nuevaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Future<void> cambiarPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null || usuario.email == null) {
      mostrarMensaje('No se pudo obtener tu cuenta.');
      return;
    }

    setState(() => cambiando = true);

    try {
      final credencial = EmailAuthProvider.credential(
        email: usuario.email!,
        password: actualController.text,
      );

      await usuario.reauthenticateWithCredential(credencial);
      await usuario.updatePassword(nuevaController.text);

      if (!mounted) return;

      mostrarMensaje('Contraseña actualizada correctamente.');
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al cambiar la contraseña: ${e.code}');

      if (!mounted) return;

      setState(() => cambiando = false);

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          mostrarMensaje('Tu contraseña actual es incorrecta.');
          break;
        case 'weak-password':
          mostrarMensaje('La nueva contraseña es demasiado débil.');
          break;
        case 'requires-recent-login':
          mostrarMensaje(
            'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
          );
          break;
        default:
          mostrarMensaje('No se pudo cambiar la contraseña.');
      }
    } catch (e) {
      debugPrint('Error inesperado al cambiar la contraseña: $e');

      if (!mounted) return;

      setState(() => cambiando = false);
      mostrarMensaje('No se pudo cambiar la contraseña. Inténtalo de nuevo.');
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  Widget campoPassword({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback alAlternar,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        obscureText: !visible,
        enabled: !cambiando,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            onPressed: alAlternar,
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Cambiar contraseña',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer,
                          scheme.surfaceContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: scheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Para proteger tu cuenta te pediremos tu contraseña actual antes de cambiarla.',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  campoPassword(
                    controller: actualController,
                    label: 'Contraseña actual',
                    visible: mostrarActual,
                    alAlternar: () =>
                        setState(() => mostrarActual = !mostrarActual),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Ingresa tu contraseña actual';
                      }
                      return null;
                    },
                  ),

                  campoPassword(
                    controller: nuevaController,
                    label: 'Nueva contraseña',
                    visible: mostrarNueva,
                    alAlternar: () =>
                        setState(() => mostrarNueva = !mostrarNueva),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Ingresa la nueva contraseña';
                      }
                      if (valor.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      if (valor == actualController.text) {
                        return 'La nueva contraseña debe ser diferente';
                      }
                      return null;
                    },
                  ),

                  campoPassword(
                    controller: confirmarController,
                    label: 'Confirmar nueva contraseña',
                    visible: mostrarNueva,
                    alAlternar: () =>
                        setState(() => mostrarNueva = !mostrarNueva),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Confirma la nueva contraseña';
                      }
                      if (valor != nuevaController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ElevatedButton(
                    onPressed: cambiando ? null : cambiarPassword,
                    child: cambiando
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: scheme.onSurfaceVariant,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('CAMBIAR CONTRASEÑA'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  OutlinedButton(
                    onPressed: cambiando ? null : () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
