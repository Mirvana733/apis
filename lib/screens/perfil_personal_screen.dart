import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/amistades_service.dart';
import '../services/cuenta_service.dart';
import '../services/preferencias_service.dart';
import '../services/verificacion_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/estrella_lulilu.dart';
import '../widgets/estrellas_reputacion.dart';
import '../widgets/fondo_lulilu.dart';
import '../widgets/hoja_comentarios.dart';
import '../widgets/tarjeta_amigo_compacta.dart';
import '../widgets/tarjeta_publicacion.dart';
import 'perfil_amigo_screen.dart';

class PerfilPersonalScreen extends StatefulWidget {
  const PerfilPersonalScreen({super.key});

  @override
  State<PerfilPersonalScreen> createState() => _PerfilPersonalScreenState();
}

class _PerfilPersonalScreenState extends State<PerfilPersonalScreen> {
  final User? usuario = FirebaseAuth.instance.currentUser;
  final ImagePicker picker = ImagePicker();

  bool eliminandoCuenta = false;

  Map<String, dynamic>? datosUsuario;
  PreferenciasPrivacidad? privacidad;

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
  }

  Future<void> cargarDatosUsuario() async {
    if (usuario == null) return;

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario!.uid)
          .get();

      if (documento.exists && mounted) {
        final datos = documento.data();
        final preferencias = datos?['preferencias'];
        final privacidadGuardada = preferencias is Map
            ? preferencias['privacidad']
            : null;

        setState(() {
          datosUsuario = datos;
          privacidad = PreferenciasPrivacidad.desdeMapa(
            privacidadGuardada is Map
                ? Map<String, dynamic>.from(privacidadGuardada)
                : null,
          );
        });
      }
    } catch (e) {
      debugPrint('Error al cargar usuario: $e');
    }
  }

  String obtenerNombre() {
    if (datosUsuario == null) {
      return 'Usuario';
    }

    final nombre = datosUsuario!['nombre'] ?? '';
    final paterno = datosUsuario!['apellidoPaterno'] ?? '';

    return '$nombre $paterno'.trim();
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> confirmarEliminarCuenta() async {
    if (eliminandoCuenta) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('¿Eliminar tu cuenta?'),
          content: const Text(
            'Se borrarán tu cuenta, tus publicaciones y comentarios de forma permanente. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      eliminandoCuenta = true;
    });

    try {
      await CuentaService.eliminarCuenta();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta fue eliminada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de autenticación al eliminar cuenta: $e');

      if (!mounted) return;

      setState(() {
        eliminandoCuenta = false;
      });

      if (e.code == 'requires-recent-login') {
        mostrarMensaje(
          'Debes iniciar sesión de nuevo para eliminar tu cuenta.',
        );
      } else {
        mostrarMensaje('No se pudo eliminar la cuenta. Inténtalo de nuevo.');
      }
    } catch (e) {
      debugPrint('Error al eliminar cuenta: $e');

      if (!mounted) return;

      setState(() {
        eliminandoCuenta = false;
      });

      mostrarMensaje('No se pudo eliminar la cuenta. Inténtalo de nuevo.');
    }
  }

  Future<void> abrirVerificacion() async {
    File? fotoCI;
    File? selfie;
    bool verificando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> elegirFotoCI() async {
              final XFile? imagen = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
                maxWidth: 1600,
              );

              if (imagen != null) {
                final XFile seleccionada = imagen;

                setSheetState(() {
                  fotoCI = File(seleccionada.path);
                });
              }
            }

            Future<void> tomarSelfie() async {
              XFile? imagen;

              try {
                imagen = await picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.front,
                  imageQuality: 80,
                  maxWidth: 1600,
                );
              } catch (_) {
                imagen = await picker.pickImage(source: ImageSource.gallery);
              }

              if (imagen != null) {
                final XFile seleccionada = imagen;

                setSheetState(() {
                  selfie = File(seleccionada.path);
                });
              }
            }

            Future<void> enviarVerificacion() async {
              if (fotoCI == null || selfie == null) {
                mostrarMensaje('Selecciona la foto de tu CI y tu selfie.');
                return;
              }

              if (datosUsuario == null) {
                mostrarMensaje('No se pudieron cargar tus datos.');
                return;
              }

              setSheetState(() {
                verificando = true;
              });

              try {
                final resultado = await VerificacionService.verificar(
                  fotoCI: fotoCI!,
                  selfie: selfie!,
                  nombre: datosUsuario!['nombre'] ?? '',
                  apellidoPaterno: datosUsuario!['apellidoPaterno'] ?? '',
                  apellidoMaterno: datosUsuario!['apellidoMaterno'] ?? '',
                  fechaNacimiento:
                      (datosUsuario!['fechaNacimiento'] as Timestamp?)
                          ?.toDate() ??
                      DateTime.now(),
                  numero: datosUsuario!['numero'] ?? '',
                );

                if (!context.mounted) return;

                Navigator.pop(context);
                mostrarMensaje(resultado.mensaje);
                await cargarDatosUsuario();
              } catch (e) {
                debugPrint('Error al verificar identidad: $e');

                if (!context.mounted) return;

                setSheetState(() {
                  verificando = false;
                });

                mostrarMensaje(
                  'No se pudo completar la verificación. Inténtalo de nuevo.',
                );
              }
            }

            final scheme = Theme.of(context).colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: scheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Verifica tu identidad',
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 22,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'La foto de tu CI y tu selfie se compararán para confirmar tu cuenta.',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _tarjetaVerificacion(
                      icono: Icons.badge_outlined,
                      titulo: fotoCI == null
                          ? 'Foto de tu CI'
                          : 'CI seleccionada',
                      color: scheme.primary,
                      onTap: elegirFotoCI,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _tarjetaVerificacion(
                      icono: Icons.face_outlined,
                      titulo: selfie == null
                          ? 'Selfie (cámara frontal)'
                          : 'Selfie tomada',
                      color: scheme.secondary,
                      onTap: tomarSelfie,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: verificando ? null : enviarVerificacion,
                        child: verificando
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: scheme.onSurfaceVariant,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verificar mi identidad'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tarjetaVerificacion({
    required IconData icono,
    required String titulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.42)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icono, color: scheme.onSurface, size: 21),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    titulo,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: scheme.onSurface,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final nombre = obtenerNombre();
    final scheme = Theme.of(context).colorScheme;
    final verificado = datosUsuario?['estadoVerificacion'] == 'verificado';
    final mostrarVerificacion = privacidad?.mostrarVerificacion ?? true;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Mi perfil',
          style: AppTextStyles.headline.copyWith(
            fontSize: 25,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            onSelected: (valor) async {
              switch (valor) {
                case 'editar':
                  await Navigator.pushNamed(context, '/editar-perfil');
                  if (mounted) cargarDatosUsuario();
                  break;
                case 'foto':
                  await Navigator.pushNamed(context, '/cambiar-foto');
                  if (mounted) cargarDatosUsuario();
                  break;
                case 'verificar':
                  abrirVerificacion();
                  break;
                case 'privacidad':
                  await Navigator.pushNamed(context, '/privacidad');
                  if (mounted) cargarDatosUsuario();
                  break;
                case 'password':
                  Navigator.pushNamed(context, '/cambiar-password');
                  break;
                case 'eliminar':
                  confirmarEliminarCuenta();
                  break;
                case 'config':
                  Navigator.pushNamed(context, '/configuracion');
                  break;
                case 'notificaciones':
                  Navigator.pushNamed(context, '/notificaciones');
                  break;
                case 'ayuda':
                  Navigator.pushNamed(context, '/ayuda');
                  break;
                case 'politica':
                  Navigator.pushNamed(context, '/politica-informacion');
                  break;
                case 'cerrar':
                  cerrarSesion();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar perfil'),
                ),
              ),
              const PopupMenuItem(
                value: 'foto',
                child: ListTile(
                  leading: Icon(Icons.image_outlined),
                  title: Text('Cambiar foto'),
                ),
              ),
              const PopupMenuItem(
                value: 'verificar',
                child: ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text('Verificar mi identidad'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'privacidad',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Privacidad'),
                ),
              ),
              const PopupMenuItem(
                value: 'password',
                child: ListTile(
                  leading: Icon(Icons.password_outlined),
                  title: Text('Cambiar contraseña'),
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: ListTile(
                  leading: Icon(Icons.delete_forever_outlined),
                  title: Text('Eliminar mi cuenta'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'config',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Configuración'),
                ),
              ),
              const PopupMenuItem(
                value: 'notificaciones',
                child: ListTile(
                  leading: Icon(Icons.notifications_none),
                  title: Text('Notificaciones'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'ayuda',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Ayuda'),
                ),
              ),
              const PopupMenuItem(
                value: 'politica',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Política de información'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'cerrar',
                child: ListTile(
                  leading: Icon(Icons.logout, color: scheme.error),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
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
                _cabeceraPerfil(
                  scheme: scheme,
                  nombre: nombre,
                  verificado: verificado,
                  mostrarVerificacion: mostrarVerificacion,
                ),
                const SizedBox(height: AppSpacing.md),
                _infoPerfil(scheme),
                if (privacidad?.mostrarAmigos ?? true) _seccionAmigos(scheme),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Mis publicaciones',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 21,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    DestelloLulilu(size: 22, color: scheme.secondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _misPublicaciones(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabeceraPerfil({
    required ColorScheme scheme,
    required String nombre,
    required bool verificado,
    required bool mostrarVerificacion,
  }) {
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
      child: Column(
        children: [
          Row(
            children: [
              AvatarUsuario(
                fotoPerfil: datosUsuario?['fotoPerfil'] as String?,
                size: 78,
                mostrarAnillo: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 23,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    ReputacionEstrellasUsuario(
                      uid: usuario?.uid ?? '',
                      size: 15,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (verificado && mostrarVerificacion)
                      _insigniaVerificado(scheme)
                    else if (!verificado)
                      Text(
                        'Verifica tu identidad para mayor confianza.',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              DestelloLulilu(size: 27, color: scheme.secondary),
            ],
          ),
          if (!verificado) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: abrirVerificacion,
                icon: const Icon(Icons.verified_user_outlined, size: 18),
                label: const Text('Verificar mi identidad'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insigniaVerificado(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Cuenta verificada',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _misPublicaciones(ColorScheme scheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publicaciones')
          .where('uidAutor', isEqualTo: usuario?.uid)
          .orderBy('fecha', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _aviso(
            scheme: scheme,
            icono: Icons.cloud_off_rounded,
            texto: 'No se pudieron cargar tus publicaciones.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _aviso(
            scheme: scheme,
            icono: Icons.auto_awesome,
            texto: 'Aún no tienes publicaciones.',
          );
        }

        return Column(
          children: docs.map((doc) {
            final datos = doc.data() as Map<String, dynamic>;

            return TarjetaPublicacion(
              publicacionId: doc.id,
              nombreAutor: obtenerNombre(),
              texto: datos['texto'] ?? '',
              uidAutor: usuario?.uid ?? '',
              mediaUrl: datos['mediaUrl'] as String?,
              totalMeGusta: (datos['likes'] as num?)?.toInt() ?? 0,
              totalComentarios: (datos['comentarios'] as num?)?.toInt() ?? 0,
              mostrarMeGusta: false,
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
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icono, color: scheme.primary, size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _infoPerfil(ColorScheme scheme) {
    final numero = (datosUsuario?['numero'] ?? '').toString();
    final fecha = datosUsuario?['fechaNacimiento'];
    final mostrarNumero = privacidad?.mostrarNumero ?? true;
    final mostrarFecha = privacidad?.mostrarFechaNacimiento ?? true;

    final filas = <Widget>[];

    if (mostrarNumero && numero.trim().isNotEmpty) {
      filas.add(
        _filaInfo(scheme, Icons.phone_outlined, 'Número de celular', numero),
      );
    }

    if (mostrarFecha && fecha is Timestamp) {
      filas.add(
        _filaInfo(
          scheme,
          Icons.cake_outlined,
          'Fecha de nacimiento',
          _formatearFecha(fecha.toDate()),
        ),
      );
    }

    if (filas.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_page_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Información de contacto',
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...filas,
        ],
      ),
    );
  }

  Widget _filaInfo(
    ColorScheme scheme,
    IconData icono,
    String etiqueta,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icono, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$etiqueta: ',
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: AppTextStyles.bodyStrong.copyWith(color: scheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Widget _seccionAmigos(ColorScheme scheme) {
    final uid = usuario?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amigos',
          style: AppTextStyles.headline.copyWith(
            fontSize: 21,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<Amistad>>(
          stream: AmistadesService.streamMias(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final amigos = (snapshot.data ?? const <Amistad>[])
                .where((amistad) => amistad.aceptada)
                .toList();

            if (amigos.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      color: scheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Aún no tienes amigos agregados.',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: amigos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final amigo = amigos[index];
                  final otroUid = uid == null ? '' : amigo.otraUid(uid);

                  return TarjetaAmigoCompacta(
                    uid: otroUid,
                    onTap: otroUid.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerfilAmigoScreen(uid: otroUid),
                            ),
                          ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
