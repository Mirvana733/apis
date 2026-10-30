import 'package:flutter/material.dart';

import '../services/perfil_publico_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'avatar_usuario.dart';
import 'estrellas_reputacion.dart';

class TarjetaAmigoCompacta extends StatelessWidget {
  const TarjetaAmigoCompacta({super.key, required this.uid, this.onTap});

  final String uid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<PerfilPublico?>(
      stream: PerfilPublicoService.streamPerfil(uid),
      builder: (context, snapshot) {
        final perfil = snapshot.data;
        final nombre = perfil?.nombre ?? 'Amigo';

        return Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            width: 102,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvatarUsuario(
                      fotoPerfil: perfil?.fotoPerfil,
                      size: 40,
                      mostrarAnillo: false,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      nombre,
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    ReputacionEstrellasUsuario(uid: uid, size: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
