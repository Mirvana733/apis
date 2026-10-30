import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notificaciones_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/encabezado_marca.dart';
import '../widgets/fondo_lulilu.dart';
import 'inicio_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  bool iniciandoSesion = false;
  bool mostrarPassword = false;
  Map<String, dynamic>? clima;
  bool cargandoClima = true;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    cargarClima();
  }

  Future<void> cargarClima() async {
    try {
      final resultado = await WeatherService.obtenerClima();

      if (!mounted) return;

      setState(() {
        clima = resultado;
        cargandoClima = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoClima = false;
      });
    }
  }

  Future<void> iniciarSesion() async {
    FocusScope.of(context).unfocus();

    final correo = correoController.text.trim();
    final password = passwordController.text;

    if (correo.isEmpty) {
      mostrarMensaje('Ingresa tu correo electrónico.');
      return;
    }

    if (!correo.contains('@')) {
      mostrarMensaje('Ingresa un correo electrónico válido.');
      return;
    }

    if (password.isEmpty) {
      mostrarMensaje('Ingresa tu contraseña.');
      return;
    }

    setState(() {
      iniciandoSesion = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );

      NotificacionesService.notificarNuevoIngreso();

      if (!mounted) return;

      setState(() {
        iniciandoSesion = false;
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const InicioShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        iniciandoSesion = false;
      });

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        mostrarMensaje('El correo o la contraseña son incorrectos.');
      } else if (e.code == 'invalid-email') {
        mostrarMensaje('El correo electrónico no es válido.');
      } else if (e.code == 'user-disabled') {
        mostrarMensaje('Esta cuenta está deshabilitada.');
      } else {
        mostrarMensaje('No se pudo iniciar sesión.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        iniciandoSesion = false;
      });

      mostrarMensaje('Ocurrió un error al iniciar sesión.');
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: Text(
          'Iniciar sesión',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EncabezadoMarca(
                      compacto: true,
                      mensaje: 'Nos alegra verte de nuevo.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _clima(scheme),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Accede a tu cuenta',
                            style: AppTextStyles.title.copyWith(
                              fontSize: 18,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: correoController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !iniciandoSesion,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: passwordController,
                            obscureText: !mostrarPassword,
                            enabled: !iniciandoSesion,
                            onSubmitted: (_) => iniciarSesion(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    mostrarPassword = !mostrarPassword;
                                  });
                                },
                                icon: Icon(
                                  mostrarPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: iniciandoSesion ? null : iniciarSesion,
                            child: iniciandoSesion
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: scheme.onSurfaceVariant,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('INICIAR SESIÓN'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'Tu información está protegida.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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

  Widget _clima(ColorScheme scheme) {
    if (cargandoClima) {
      return Container(
        height: 82,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (clima == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              WeatherService.iconoClima(
                clima!['codigo'] as int,
                clima!['esDeDia'] as bool,
              ),
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cochabamba',
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${clima!['temperatura']} °C · '
                  '${WeatherService.descripcionClima(clima!['codigo'] as int)}',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.water_drop_outlined, color: scheme.primary, size: 20),
        ],
      ),
    );
  }
}
