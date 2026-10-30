import 'package:flutter/material.dart';

import '../theme/app_ajustes.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/ajustes_widgets.dart';
import '../widgets/fondo_lulilu.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  static const double _textoPequeno = 0.9;
  static const double _textoNormal = 1.0;
  static const double _textoGrande = 1.15;
  static const double _textoMuyGrande = 1.3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: ListenableBuilder(
          listenable: AppAjustes.instancia,
          builder: (context, _) {
            final ajustes = AppAjustes.instancia;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            Icons.tune_rounded,
                            color: scheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Personaliza la apariencia y la accesibilidad de Lulilu.',
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

                    SeccionAjustes(
                      titulo: 'Apariencia',
                      hijos: [
                        AjusteOpcion<ThemeMode>(
                          titulo: 'Tema del sistema',
                          descripcion:
                              'Usa el modo claro u oscuro según tu teléfono.',
                          valor: ThemeMode.system,
                          grupo: ajustes.tema,
                          onChanged: (valor) => ajustes.cambiarTema(valor),
                        ),
                        AjusteOpcion<ThemeMode>(
                          titulo: 'Tema claro',
                          valor: ThemeMode.light,
                          grupo: ajustes.tema,
                          onChanged: (valor) => ajustes.cambiarTema(valor),
                        ),
                        AjusteOpcion<ThemeMode>(
                          titulo: 'Tema oscuro',
                          valor: ThemeMode.dark,
                          grupo: ajustes.tema,
                          onChanged: (valor) => ajustes.cambiarTema(valor),
                        ),
                      ],
                    ),

                    SeccionAjustes(
                      titulo: 'Tamaño de texto',
                      hijos: [
                        AjusteOpcion<double>(
                          titulo: 'Pequeño',
                          valor: _textoPequeno,
                          grupo: ajustes.escalaTexto,
                          onChanged: (valor) =>
                              ajustes.cambiarEscalaTexto(valor),
                        ),
                        AjusteOpcion<double>(
                          titulo: 'Normal',
                          valor: _textoNormal,
                          grupo: ajustes.escalaTexto,
                          onChanged: (valor) =>
                              ajustes.cambiarEscalaTexto(valor),
                        ),
                        AjusteOpcion<double>(
                          titulo: 'Grande',
                          valor: _textoGrande,
                          grupo: ajustes.escalaTexto,
                          onChanged: (valor) =>
                              ajustes.cambiarEscalaTexto(valor),
                        ),
                        AjusteOpcion<double>(
                          titulo: 'Muy grande',
                          valor: _textoMuyGrande,
                          grupo: ajustes.escalaTexto,
                          onChanged: (valor) =>
                              ajustes.cambiarEscalaTexto(valor),
                        ),
                      ],
                    ),

                    SeccionAjustes(
                      titulo: 'Cuenta',
                      hijos: [
                        AjusteNavegacion(
                          icono: Icons.lock_outline,
                          titulo: 'Cambiar contraseña',
                          descripcion: 'Actualiza tu contraseña de acceso.',
                          onTap: () =>
                              Navigator.pushNamed(context, '/cambiar-password'),
                        ),
                        AjusteNavegacion(
                          icono: Icons.notifications_none,
                          titulo: 'Notificaciones',
                          descripcion: 'Elige qué avisos quieres recibir.',
                          onTap: () =>
                              Navigator.pushNamed(context, '/notificaciones'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
