import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'avatar_usuario.dart';
import 'boton_me_gusta.dart';
import 'estrella_lulilu.dart';
import 'estrellas_reputacion.dart';

class TarjetaPublicacion extends StatelessWidget {
  const TarjetaPublicacion({
    super.key,
    required this.publicacionId,
    required this.nombreAutor,
    required this.texto,
    this.uidAutor = '',
    this.mediaUrl,
    this.totalMeGusta = 0,
    this.totalComentarios = 0,
    this.mostrarMeGusta = true,
    this.onComentarios,
  });

  final String publicacionId;
  final String nombreAutor;
  final String texto;
  final String uidAutor;
  final String? mediaUrl;
  final int totalMeGusta;
  final int totalComentarios;
  final bool mostrarMeGusta;
  final VoidCallback? onComentarios;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tieneMedia = mediaUrl != null && mediaUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                AvatarUsuario(fotoPerfil: null, size: 44, mostrarAnillo: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreAutor,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'En la comunidad Lulilu',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (uidAutor.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ReputacionEstrellasUsuario(
                            uid: uidAutor,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: DestelloLulilu(size: 17, color: scheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          if (tieneMedia)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: _media(context),
                ),
              ),
            ),
          if (texto.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                tieneMedia ? AppSpacing.md : AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                texto,
                style: AppTextStyles.body.copyWith(color: scheme.onSurface),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xxs,
            ),
            child: Row(
              children: [
                if (mostrarMeGusta)
                  BotonMeGusta(
                    key: ValueKey<String>('me-gusta-$publicacionId'),
                    publicacionId: publicacionId,
                    totalInicial: totalMeGusta,
                  ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onComentarios,
                  icon: const Icon(Icons.mode_comment_outlined),
                  color: scheme.onSurface,
                  iconSize: 20,
                  tooltip: 'Comentarios',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '$totalComentarios',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (mostrarMeGusta) const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _media(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = mediaUrl;

    if (url == null || url.isEmpty) {
      return _mediaInvalida(scheme);
    }

    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(url).getDownloadURL(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.network(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _mediaInvalida(scheme),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _cargandoMedia(scheme);
            },
          );
        }

        if (snapshot.hasError) {
          return _mediaInvalida(scheme);
        }

        return _cargandoMedia(scheme);
      },
    );
  }

  Widget _cargandoMedia(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _mediaInvalida(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 44,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
