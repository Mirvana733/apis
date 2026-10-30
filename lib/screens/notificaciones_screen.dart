import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/ajustes_widgets.dart';
import '../widgets/fondo_lulilu.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  PreferenciasNotificaciones? preferencias;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      final valores = await PreferenciasService.cargarNotificaciones();

      if (!mounted) return;

      setState(() {
        preferencias = valores;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar las notificaciones: $e');

      if (!mounted) return;

      setState(() {
        preferencias = const PreferenciasNotificaciones();
        cargando = false;
      });
    }
  }

  Future<void> actualizar(PreferenciasNotificaciones nuevos) async {
    final anterior = preferencias!;

    setState(() => preferencias = nuevos);

    try {
      await PreferenciasService.guardarNotificaciones(nuevos);
    } catch (e) {
      debugPrint('Error al guardar las notificaciones: $e');

      if (!mounted) return;

      setState(() => preferencias = anterior);
      mostrarMensaje('No se pudieron guardar los cambios.');
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
        title: Text(
          'Notificaciones',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: cargando
          ? const FondoLulilu(child: Center(child: CircularProgressIndicator()))
          : FondoLulilu(
              child: SafeArea(
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
                              Icons.mark_email_unread_outlined,
                              color: scheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Lulilu te avisa por correo. Elige qué mensajes quieres recibir.',
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
                        titulo: 'Correos',
                        hijos: [
                          AjusteSwitch(
                            icono: Icons.mark_email_read_outlined,
                            titulo: 'Recibir correos de Lulilu',
                            descripcion: 'Interruptor general de todos los avisos por correo.',
                            valor: preferencias!.correosActivos,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(correosActivos: valor),
                            ),
                          ),
                        ],
                      ),

                      SeccionAjustes(
                        titulo: 'Tipos de aviso',
                        hijos: [
                          AjusteSwitch(
                            icono: Icons.celebration_outlined,
                            titulo: 'Correos de cuenta y bienvenida',
                            descripcion: 'Mensajes sobre la creación y el estado de tu cuenta.',
                            valor: preferencias!.correoBienvenida,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(correoBienvenida: valor),
                            ),
                          ),
                          AjusteSwitch(
                            icono: Icons.lock_outline,
                            titulo: 'Avisos de inicio de sesión',
                            descripcion: 'Te avisamos cuando se inicie sesión desde un dispositivo nuevo.',
                            valor: preferencias!.avisoNuevoIngreso,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(avisoNuevoIngreso: valor),
                            ),
                          ),
                        ],
                      ),

                      Text(
                        'Los cambios se guardan automáticamente. Si desactivas los correos, no se enviará ningún aviso.',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
