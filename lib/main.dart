import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/ayuda_screen.dart';
import 'screens/cambiar_foto_screen.dart';
import 'screens/cambiar_password_screen.dart';
import 'screens/configuracion_screen.dart';
import 'screens/editar_perfil_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notificaciones_screen.dart';
import 'screens/perfil_personal_screen.dart';
import 'screens/politica_informacion_screen.dart';
import 'screens/privacidad_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/top_semana_screen.dart';
import 'services/weather_service.dart';
import 'theme/app_ajustes.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'widgets/encabezado_marca.dart';
import 'widgets/estrella_lulilu.dart';
import 'widgets/fondo_lulilu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppAjustes.instancia.cargar();

  const bool usarEmulador = bool.fromEnvironment('USE_EMULADOR');

  if (usarEmulador) {
    FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);
  }

  runApp(const LuliluApp());
}

class LuliluApp extends StatelessWidget {
  const LuliluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppAjustes.instancia,
      builder: (context, _) {
        final ajustes = AppAjustes.instancia;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lulilu',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ajustes.tema,
          builder: (context, child) {
            final media = MediaQuery.of(context);

            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(ajustes.escalaTexto),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const InicioScreen(),
          routes: {
            '/perfil-personal': (context) => const PerfilPersonalScreen(),
            '/editar-perfil': (context) => const EditarPerfilScreen(),
            '/cambiar-foto': (context) => const CambiarFotoScreen(),
            '/cambiar-password': (context) => const CambiarPasswordScreen(),
            '/privacidad': (context) => const PrivacidadScreen(),
            '/configuracion': (context) => const ConfiguracionScreen(),
            '/notificaciones': (context) => const NotificacionesScreen(),
            '/ayuda': (context) => const AyudaScreen(),
            '/politica-informacion': (context) =>
                const PoliticaInformacionScreen(),
            '/top-semana': (context) => const TopSemanaScreen(),
          },
        );
      },
    );
  }
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  Map<String, dynamic>? clima;
  bool cargandoClima = true;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FondoLulilu(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const EncabezadoMarca(
                      mensaje: 'Conecta, comparte y comunica con respeto.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _tarjetaClima(),
                    const SizedBox(height: AppSpacing.lg),
                    _bienvenida(scheme),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      ),
                      child: const Text('INICIAR SESIÓN'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistroScreen(),
                        ),
                      ),
                      child: const Text('REGISTRARSE'),
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
                            'Un espacio con privacidad y respeto.',
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

  Widget _bienvenida(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: EstrellaLulilu(size: 24, color: scheme.secondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un lugar para compartir a tu ritmo',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 17,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Descubre publicaciones, conversa con la comunidad y participa en el Top de la semana.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaClima() {
    final scheme = Theme.of(context).colorScheme;

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
