import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/moderacion_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class HojaComentarios extends StatefulWidget {
  const HojaComentarios({super.key, this.publicacionId});

  final String? publicacionId;

  static Future<void> mostrar(BuildContext context, {String? publicacionId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => HojaComentarios(publicacionId: publicacionId),
    );
  }

  @override
  State<HojaComentarios> createState() => _HojaComentariosState();
}

class _HojaComentariosState extends State<HojaComentarios> {
  final controlador = TextEditingController();
  bool analizando = false;

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final comentario = controlador.text.trim();

    if (comentario.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      analizando = true;
    });

    try {
      final resultado = await ModeracionService.publicarComentario(
        comentario,
        publicacionId: widget.publicacionId,
      );

      if (!mounted) return;

      if (resultado.aprobado) {
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Comentario publicado correctamente.')),
        );
      } else {
        setState(() {
          analizando = false;
        });

        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Este comentario no puede publicarse porque contiene contenido inapropiado.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        analizando = false;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo analizar el comentario.')),
      );

      debugPrint('Error al analizar comentario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.mode_comment_outlined,
                          size: 19,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Comentarios',
                          style: AppTextStyles.title.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(child: _lista()),
            _campo(scheme),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    if (widget.publicacionId == null || widget.publicacionId!.isEmpty) {
      return _aviso('Abre los comentarios desde una publicación.');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comentarios')
          .where('publicacionId', isEqualTo: widget.publicacionId)
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final scheme = Theme.of(context).colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _aviso('No se pudieron cargar los comentarios.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _aviso('Aún no hay comentarios. ¡Sé el primero! 👋');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: docs.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final datos = docs[index].data() as Map<String, dynamic>;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: scheme.onPrimaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          datos['nombreAutor'] ?? 'Usuario',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          datos['texto'] ?? '',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _aviso(String texto) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 42,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controlador,
              maxLines: 3,
              minLines: 1,
              enabled: !analizando,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Escribe un comentario...',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 50,
            height: 50,
            child: FilledButton(
              onPressed: analizando ? null : _enviar,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: analizando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: scheme.onSurfaceVariant,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: scheme.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
