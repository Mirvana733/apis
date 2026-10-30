import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/perfil_publico_service.dart';
import '../services/publicacion_service.dart';
import '../services/top_semana_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/estrella_lulilu.dart';
import '../widgets/estrellas_reputacion.dart';
import '../widgets/fondo_lulilu.dart';
import '../widgets/hoja_comentarios.dart';
import '../widgets/tarjeta_publicacion.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, this.onPerfilTap});

  final VoidCallback? onPerfilTap;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  Map<String, dynamic>? datosUsuario;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
    _sincronizarPrivacidad();
  }

  Future<void> _sincronizarPrivacidad() async {
    try {
      await Future.wait([
        TopSemanaService.sincronizarCuentaPublica(),
        PerfilPublicoService.sincronizarActual(),
      ]);

      if (!mounted) return;

      await cargarDatosUsuario();
    } catch (e) {
      debugPrint('Error al sincronizar privacidad: $e');
    }
  }

  Future<void> cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!mounted) return;

      setState(() {
        datosUsuario = doc.data();
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
  }

  String obtenerNombre() {
    final datos = datosUsuario;

    if (datos == null) return 'Lulilu';

    final nombre = datos['nombre']?.toString().trim();

    if (nombre == null || nombre.isEmpty) return 'Lulilu';

    return nombre;
  }

  bool get cuentaVerificada {
    return datosUsuario?['estadoVerificacion'] == 'verificado';
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> abrirOpcionesPublicacion() async {
    final scheme = Theme.of(context).colorScheme;

    final opcion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¿Qué quieres compartir?',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 22,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Elige cómo quieres aparecer en la comunidad.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _opcionPublicar(
                  icono: Icons.edit_outlined,
                  titulo: 'Escribir una publicación',
                  descripcion: 'Comparte lo que sientes o piensas.',
                  color: scheme.primary,
                  onTap: () => Navigator.pop(context, 'texto'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _opcionPublicar(
                  icono: Icons.photo_library_outlined,
                  titulo: 'Compartir una foto',
                  descripcion: 'Añade una imagen a tu historia.',
                  color: scheme.secondary,
                  onTap: () => Navigator.pop(context, 'foto'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (opcion == 'texto') {
      await publicarTexto();
    } else if (opcion == 'foto') {
      await crearPublicacion();
    }
  }

  Widget _opcionPublicar({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icono, color: scheme.onSurface, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        descripcion,
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> publicarTexto() async {
    final controlador = TextEditingController();

    final texto = await showDialog<String>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Nueva publicación'),
          content: TextField(
            controller: controlador,
            maxLines: 5,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: '¿Qué quieres compartir?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controlador.text.trim());
              },
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );

    controlador.dispose();

    if (texto == null || texto.isEmpty) return;

    setState(() {
      cargando = true;
    });
    final resultado = await PublicacionService.publicarTexto(texto);

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

    mostrarMensaje(resultado.mensaje);
  }

  Future<void> crearPublicacion() async {
    final imagen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );

    if (imagen == null) return;

    if (!mounted) return;

    mostrarMensaje('Analizando tu imagen...');

    try {
      final resultado = await PublicacionService.publicarImagen(
        File(imagen.path),
      );

      if (!mounted) return;

      mostrarMensaje(resultado.mensaje);
    } catch (e) {
      debugPrint('Error al publicar imagen: $e');

      if (!mounted) return;

      mostrarMensaje('No se pudo publicar la imagen. Inténtalo de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nombre = obtenerNombre();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        titleSpacing: AppSpacing.lg,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: EstrellaLulilu(size: 19, color: scheme.secondary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Lulilu',
              style: AppTextStyles.headline.copyWith(
                fontSize: 25,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.full),
              onTap:
                  widget.onPerfilTap ??
                  () => Navigator.pushNamed(context, '/perfil-personal'),
              child: AvatarUsuario(
                fotoPerfil: datosUsuario?['fotoPerfil'] as String?,
                size: 38,
                mostrarAnillo: true,
              ),
            ),
          ),
        ],
      ),
      body: FondoLulilu(
        child: RefreshIndicator(
          onRefresh: cargarDatosUsuario,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tarjetaPerfil(scheme: scheme, nombre: nombre),
                const SizedBox(height: AppSpacing.md),
                _crearPublicacion(scheme),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Text(
                      'Publicaciones',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 21,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            'Comunidad',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _publicaciones(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaPerfil({required ColorScheme scheme, required String nombre}) {
    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          AvatarUsuario(
            fotoPerfil: datosUsuario?['fotoPerfil'] as String?,
            size: 70,
            mostrarAnillo: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola,',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 23,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                ReputacionEstrellasUsuario(
                  uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                  size: 14,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (cuentaVerificada)
                  _insignia(
                    scheme: scheme,
                    icono: Icons.verified_rounded,
                    texto: 'Cuenta verificada',
                    fondo: scheme.secondaryContainer,
                    color: scheme.onSecondaryContainer,
                  )
                else
                  Text(
                    'Tu espacio para compartir con calma.',
                    maxLines: 2,
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          DestelloLulilu(size: 26, color: scheme.secondary),
        ],
      ),
    );
  }

  Widget _insignia({
    required ColorScheme scheme,
    required IconData icono,
    required String texto,
    required Color fondo,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            texto,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _crearPublicacion(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: abrirOpcionesPublicacion,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '¿Qué quieres compartir hoy?',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              FilledButton(
                onPressed: abrirOpcionesPublicacion,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: const Text('Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _publicaciones(ColorScheme scheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publicaciones')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _aviso(
            scheme: scheme,
            icono: Icons.cloud_off_rounded,
            titulo: 'No se pudieron cargar las publicaciones',
            detalle: 'Revisa tu conexión e inténtalo de nuevo.',
          );
        }

        final publicaciones = snapshot.data?.docs ?? [];

        if (publicaciones.isEmpty) {
          return _aviso(
            scheme: scheme,
            icono: Icons.auto_awesome,
            titulo: 'Aún no hay publicaciones',
            detalle: 'Comparte el primer momento de la comunidad.',
          );
        }

        return Column(
          children: publicaciones.map((doc) {
            final datos = doc.data() as Map<String, dynamic>;

            return TarjetaPublicacion(
              publicacionId: doc.id,
              nombreAutor: datos['nombreAutor'] ?? 'Usuario Lulilu',
              texto: datos['texto'] ?? '',
              uidAutor: (datos['uidAutor'] ?? '').toString(),
              mediaUrl: datos['mediaUrl'] as String?,
              totalMeGusta: (datos['likes'] as num?)?.toInt() ?? 0,
              totalComentarios: (datos['comentarios'] as num?)?.toInt() ?? 0,
              onComentarios: () =>
                  HojaComentarios.mostrar(context, publicacionId: doc.id),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _aviso({
    required ColorScheme scheme,
    required IconData icono,
    required String titulo,
    required String detalle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icono, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
