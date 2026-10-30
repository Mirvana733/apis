import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/amistades_service.dart';
import '../services/calificaciones_service.dart';
import '../services/perfil_publico_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/estrella_lulilu.dart';
import '../widgets/estrellas_reputacion.dart';
import '../widgets/fondo_lulilu.dart';
import 'perfil_amigo_screen.dart';

class EstrellasScreen extends StatelessWidget {
  const EstrellasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Estrellas',
          style: AppTextStyles.headline.copyWith(
            fontSize: 25,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _resumen(scheme, uid),
                const SizedBox(height: AppSpacing.lg),
                _explicacion(scheme),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(Icons.group_outlined, size: 18, color: scheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Califica a tus amigos',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 17,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _amigos(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumen(ColorScheme scheme, String uid) {
    return StreamBuilder<Reputacion>(
      stream: CalificacionesService.streamReputacion(uid),
      builder: (context, snapshot) {
        final reputacion = snapshot.data ?? const Reputacion.vacia();
        final promedio = reputacion.total == 0
            ? '0.0'
            : reputacion.promedio.toStringAsFixed(1);
        final personas = reputacion.total == 1
            ? '1 persona'
            : '${reputacion.total} personas';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primaryContainer, scheme.surfaceContainer],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: EstrellaLulilu(size: 28, color: scheme.secondary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tu reputación',
                style: AppTextStyles.title.copyWith(
                  fontSize: 18,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              EstrellasReputacion(
                promedio: reputacion.promedio,
                total: reputacion.total,
                size: 34,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$promedio de 5',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 30,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                personas,
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _explicacion(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tus amigos pueden darte una calificación diaria. Se conserva la más reciente de cada persona y las calificaciones anteriores quedan en tu historial privado.',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amigos(ColorScheme scheme) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<Amistad>>(
      stream: AmistadesService.streamMias(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _aviso(scheme, 'No se pudieron cargar tus amigos.');
        }

        final amigos = (snapshot.data ?? const <Amistad>[])
            .where((amistad) => amistad.aceptada)
            .toList();

        if (amigos.isEmpty) {
          return _aviso(scheme, 'Agrega amigos para poder calificarlos.');
        }

        return Column(
          children: amigos.map((amistad) {
            final otroUid = amistad.otraUid(uid);

            return StreamBuilder<PerfilPublico?>(
              stream: PerfilPublicoService.streamPerfil(otroUid),
              builder: (context, snapshot) {
                final perfil = snapshot.data;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilAmigoScreen(uid: otroUid),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            AvatarUsuario(
                              fotoPerfil: perfil?.fotoPerfil,
                              size: 44,
                              mostrarAnillo: false,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    perfil?.nombre ?? 'Amigo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyStrong.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  ReputacionEstrellasUsuario(
                                    uid: otroUid,
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.star_outline_rounded,
                              color: scheme.secondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _aviso(ColorScheme scheme, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
