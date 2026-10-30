import 'package:flutter/material.dart';

import '../services/perfil_publico_service.dart';
import '../services/preferencias_service.dart';
import '../services/top_semana_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/ajustes_widgets.dart';
import '../widgets/fondo_lulilu.dart';

class PrivacidadScreen extends StatefulWidget {
  const PrivacidadScreen({super.key});

  @override
  State<PrivacidadScreen> createState() => _PrivacidadScreenState();
}

class _PrivacidadScreenState extends State<PrivacidadScreen> {
  PreferenciasPrivacidad? preferencias;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      final valores = await PreferenciasService.cargarPrivacidad();

      if (!mounted) return;

      setState(() {
        preferencias = valores;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar la privacidad: $e');

      if (!mounted) return;

      setState(() {
        preferencias = const PreferenciasPrivacidad();
        cargando = false;
      });
    }
  }

  Future<void> actualizar(PreferenciasPrivacidad nuevos) async {
    final anterior = preferencias!;

    setState(() => preferencias = nuevos);

    try {
      await PreferenciasService.guardarPrivacidad(nuevos);

      try {
        await PerfilPublicoService.sincronizarActual();
      } catch (e) {
        debugPrint('No se pudo sincronizar el perfil público: $e');
      }
    } catch (e) {
      debugPrint('Error al guardar la privacidad: $e');

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

  /// Cambia la preferencia "Mostrar mi Top" y la refleja en las
  /// publicaciones del usuario (`mostrarEnTop`), porque las reglas impiden
  /// que otros usuarios lean este documento.
  Future<void> _cambiarMostrarTop(bool valor) async {
    final anterior = preferencias!;

    setState(() => preferencias = anterior.copiarCon(mostrarTop: valor));

    try {
      await PreferenciasService.guardarPrivacidad(preferencias!);
      await TopSemanaService.actualizarVisibilidadTop(valor);
    } catch (e) {
      debugPrint('Error al guardar "Mostrar mi Top": $e');

      if (!mounted) return;

      setState(() => preferencias = anterior);
      mostrarMensaje('No se pudieron guardar los cambios.');
    }
  }

  /// Cambia "Perfil público" y refleja la nueva privacidad en las
  /// publicaciones del usuario (`cuentaPublica`), porque las reglas impiden
  /// que otros lean el documento `usuarios/{uid}`.
  Future<void> _cambiarPerfilPublico(bool valor) async {
    final anterior = preferencias!;
    final nuevos = anterior.copiarCon(perfilPublico: valor);

    setState(() => preferencias = nuevos);

    try {
      await PreferenciasService.guardarPrivacidad(nuevos);
      await TopSemanaService.actualizarCuentaPublica(valor);

      try {
        await PerfilPublicoService.sincronizarActual();
      } catch (e) {
        debugPrint('No se pudo sincronizar el perfil público: $e');
      }
    } catch (e) {
      debugPrint('Error al guardar el perfil público: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Privacidad',
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
                              Icons.shield_outlined,
                              color: scheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Controla qué información tuya pueden ver otros usuarios.',
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
                        titulo: 'Visibilidad de tu perfil',
                        hijos: [
                          AjusteSwitch(
                            icono: Icons.public,
                            titulo: 'Perfil público',
                            descripcion:
                                'Permite que otros usuarios encuentren tu perfil. '
                                'Si lo desactivas, tus publicaciones no aparecen en el Top.',
                            valor: preferencias!.perfilPublico,
                            onChanged: _cambiarPerfilPublico,
                          ),
                          AjusteSwitch(
                            icono: Icons.phone_outlined,
                            titulo: 'Mostrar número de celular',
                            descripcion: 'Muestra tu número en tu perfil.',
                            valor: preferencias!.mostrarNumero,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(mostrarNumero: valor),
                            ),
                          ),
                          AjusteSwitch(
                            icono: Icons.cake_outlined,
                            titulo: 'Mostrar fecha de nacimiento',
                            descripcion:
                                'Muestra tu fecha de nacimiento en tu perfil.',
                            valor: preferencias!.mostrarFechaNacimiento,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(
                                mostrarFechaNacimiento: valor,
                              ),
                            ),
                          ),
                          AjusteSwitch(
                            icono: Icons.group_outlined,
                            titulo: 'Mostrar mi lista de amigos',
                            descripcion: 'Hace visible la sección de amigos en tu perfil.',
                            valor: preferencias!.mostrarAmigos,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(mostrarAmigos: valor),
                            ),
                          ),
                          AjusteSwitch(
                            icono: Icons.verified_outlined,
                            titulo: 'Mostrar distintivo de verificación',
                            descripcion: 'Muestra el check azul si verificaste tu identidad.',
                            valor: preferencias!.mostrarVerificacion,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(
                                mostrarVerificacion: valor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SeccionAjustes(
                        titulo: 'Publicaciones e interacción',
                        hijos: [
                          AjusteSwitch(
                            icono: Icons.mode_comment_outlined,
                            titulo: 'Permitir comentarios',
                            descripcion: 'Permite que otros usuarios comenten tus publicaciones.',
                            valor: preferencias!.permitirComentarios,
                            onChanged: (valor) => actualizar(
                              preferencias!.copiarCon(
                                permitirComentarios: valor,
                              ),
                            ),
                          ),
                          AjusteSwitch(
                            icono: Icons.star_rounded,
                            titulo: 'Mostrar mi Top',
                            descripcion: 'Permite que tus publicaciones aparezcan en el Top de la semana.',
                            valor: preferencias!.mostrarTop,
                            onChanged: _cambiarMostrarTop,
                          ),
                        ],
                      ),

                      Text(
                        'Los cambios se guardan automáticamente.',
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
