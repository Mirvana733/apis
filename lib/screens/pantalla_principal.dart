import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cuenta_service.dart';
import '../services/moderacion_service.dart';
import '../services/publicacion_service.dart';
import '../services/verificacion_service.dart';
import '../theme/app_colors.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final User? usuario = FirebaseAuth.instance.currentUser;
  final ImagePicker picker = ImagePicker();

  bool eliminandoCuenta = false;

  Map<String, dynamic>? datosUsuario;

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
        setState(() {
          datosUsuario = documento.data();
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

  // ==========================================
  // CERRAR SESIÓN
  // ==========================================

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  // ==========================================
  // MENÚ PERSONAL
  // ==========================================

  void abrirMenuPersonal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cyan,
                              AppColors.purple,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mi cuenta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              obtenerNombre(),
                              style: TextStyle(
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'MI PERFIL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purpleText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.edit_outlined,
                    titulo: 'Editar perfil',
                    subtitulo: 'Personaliza tu información',
                    color: AppColors.cyan,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Próximamente podrás editar tu perfil.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.image_outlined,
                    titulo: 'Cambiar foto',
                    subtitulo: 'Actualiza tu foto de perfil',
                    color: AppColors.green,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Próximamente podrás cambiar tu foto.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.verified_user_outlined,
                    titulo: 'Verificar mi identidad',
                    subtitulo: 'Confirma tu cuenta con tu CI',
                    color: AppColors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      abrirVerificacion();
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'PRIVACIDAD',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purpleText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.lock_outline,
                    titulo: 'Privacidad',
                    subtitulo: 'Controla quién puede ver tu cuenta',
                    color: AppColors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Configuración de privacidad.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

_opcionMenu(
                    icono: Icons.password_outlined,
                    titulo: 'Cambiar contraseña',
                    subtitulo: 'Actualiza tu contraseña',
                    color: AppColors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Cambio de contraseña.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.delete_forever_outlined,
                    titulo: 'Eliminar mi cuenta',
                    subtitulo:
                        'Borra tu cuenta y tus datos de forma permanente',
                    color: AppColors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      confirmarEliminarCuenta();
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'CONFIGURACIÓN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purpleText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.settings_outlined,
                    titulo: 'Configuración',
                    subtitulo: 'Personaliza tu experiencia',
                    color: AppColors.cyan,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Configuración de Lulilu.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.password_outlined,
                    titulo: 'Cambiar contraseña',
                    subtitulo: 'Actualiza tu contraseña',
                    color: AppColors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Cambio de contraseña.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.notifications_none,
                    titulo: 'Notificaciones',
                    subtitulo: 'Administra tus notificaciones',
                    color: AppColors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Configuración de notificaciones.',
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'AYUDA E INFORMACIÓN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purpleText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.help_outline,
                    titulo: 'Ayuda',
                    subtitulo: 'Encuentra respuestas y soporte',
                    color: AppColors.green,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Centro de ayuda.',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  _opcionMenu(
                    icono: Icons.description_outlined,
                    titulo: 'Política de información',
                    subtitulo:
                        'Conoce cómo protegemos tu información',
                    color: AppColors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      mostrarMensaje(
                        'Política de información.',
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await cerrarSesion();
                      },
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.redAccent,
                      ),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: AppColors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.redAccentLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _opcionMenu({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                color: color,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: AppColors.grey500,
            ),
          ],
        ),
      ),
    );
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // ELIMINAR CUENTA
  // ==========================================

  Future<void> confirmarEliminarCuenta() async {
    if (eliminandoCuenta) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar tu cuenta?'),
          content: const Text(
            'Se borrarán tu cuenta, tus publicaciones y comentarios de forma permanente. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.redAccent,
                foregroundColor: AppColors.white,
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

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
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
        mostrarMensaje(
          'No se pudo eliminar la cuenta. Inténtalo de nuevo.',
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar cuenta: $e');

      if (!mounted) return;

      setState(() {
        eliminandoCuenta = false;
      });

      mostrarMensaje(
        'No se pudo eliminar la cuenta. Inténtalo de nuevo.',
      );
    }
  }

  // ==========================================
  // CREAR PUBLICACIÓN (TEXTO O IMAGEN)
  // ==========================================

  Future<void> abrirOpcionesPublicacion() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    '¿Qué quieres publicar?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _opcionPublicar(
                  icono: Icons.text_fields,
                  titulo: 'Texto',
                  descripcion: 'Escribe una publicación',
                  color: AppColors.cyan,
                  onTap: () => Navigator.pop(context, 'texto'),
                ),
                const SizedBox(height: 10),
                _opcionPublicar(
                  icono: Icons.image_outlined,
                  titulo: 'Imagen',
                  descripcion: 'Comparte una foto desde tu galería',
                  color: AppColors.purple,
                  onTap: () => Navigator.pop(context, 'imagen'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || opcion == null) return;

    if (opcion == 'texto') {
      await publicarTexto();
    } else {
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PUBLICAR TEXTO CON MODERACIÓN
  // ==========================================

  Future<void> publicarTexto() async {
    final controlador = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool publicando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> enviar() async {
              final texto = controlador.text.trim();

              if (texto.isEmpty) return;

              setDialogState(() {
                publicando = true;
              });

              final resultado = await PublicacionService.publicarTexto(texto);

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);

              if (!mounted) return;
              mostrarMensaje(resultado.mensaje);
            }

            return AlertDialog(
              title: const Text('Escribe tu publicación'),
              content: TextField(
                controller: controlador,
                maxLines: 5,
                minLines: 3,
                maxLength: 1000,
                enabled: !publicando,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: '¿Qué quieres compartir?',
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: publicando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: publicando ? null : enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: AppColors.white,
                  ),
                  child: publicando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );

    controlador.dispose();
  }

  // ==========================================
  // CREAR PUBLICACIÓN CON MODERACIÓN DE IMAGEN
  // ==========================================

  Future<void> crearPublicacion() async {
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );

    if (imagen == null) return;

    if (!mounted) return;
    mostrarMensaje('Analizando tu imagen...');

    try {
      final resultado = await PublicacionService.publicarImagen(File(imagen.path));

      if (!mounted) return;
      mostrarMensaje(resultado.mensaje);
    } catch (e) {
      debugPrint('Error al publicar imagen: $e');

      if (!mounted) return;
      mostrarMensaje('No se pudo publicar la imagen. Inténtalo de nuevo.');
    }
  }

  // ==========================================
  // VERIFICAR IDENTIDAD (KYC)
  // ==========================================

  Future<void> abrirVerificacion() async {
    File? fotoCI;
    File? selfie;
    bool verificando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
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
                imagen = await picker.pickImage(
                  source: ImageSource.gallery,
                );
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
                mostrarMensaje(
                  'Selecciona la foto de tu CI y tu selfie.',
                );
                return;
              }

              if (datosUsuario == null) {
                mostrarMensaje(
                  'No se pudieron cargar tus datos.',
                );
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

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Verifica tu identidad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'La foto de tu CI y tu selfie se compararán para confirmar tu cuenta.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _tarjetaVerificacion(
                      icono: Icons.badge_outlined,
                      titulo:
                          fotoCI == null ? 'Foto de tu CI' : 'CI seleccionada',
                      color: AppColors.cyan,
                      onTap: elegirFotoCI,
                    ),

                    const SizedBox(height: 12),

                    _tarjetaVerificacion(
                      icono: Icons.face_outlined,
                      titulo:
                          selfie == null ? 'Selfie (cámara frontal)' : 'Selfie tomada',
                      color: AppColors.purple,
                      onTap: tomarSelfie,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: verificando ? null : enviarVerificacion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: verificando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 26),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMENTARIOS CON MODERACIÓN
  // ==========================================

  Future<void> mostrarComentarios({String? publicacionId}) async {
    final controlador = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        bool analizando = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> enviarComentario() async {
              final comentario = controlador.text.trim();

              if (comentario.isEmpty) {
                return;
              }

              setModalState(() {
                analizando = true;
              });

              try {
                final resultado = await ModeracionService
                    .publicarComentario(
                  comentario,
                  publicacionId: publicacionId,
                );

                if (!context.mounted) return;

                if (resultado.aprobado) {
                  Navigator.pop(context);

                  mostrarMensaje(
                    'Comentario publicado correctamente. 💗',
                  );
                } else {
                  setModalState(() {
                    analizando = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Este comentario no puede publicarse porque contiene contenido inapropiado.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;

                setModalState(() {
                  analizando = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No se pudo analizar el comentario.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                debugPrint(
                  'Error al analizar comentario: $e',
                );
              }
            }

            Widget listaComentarios() {
              if (publicacionId == null ||
                  publicacionId.isEmpty) {
                return const Center(
                  child: Text('Abre los comentarios desde una publicación.'),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comentarios')
                    .where(
                      'publicacionId',
                      isEqualTo: publicacionId,
                    )
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.cyan,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'No se pudieron cargar los comentarios.',
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay comentarios. ¡Sé el primero! 👋',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 3),
                    itemBuilder: (context, index) {
                      final datos = docs[index].data() as Map<String, dynamic>;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.purple.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.purple,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          datos['nombreAutor'] ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          datos['texto'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    },
                  );
                },
              );
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      12,
                      5,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Comentarios',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: AppColors.grey600,
                        ),
                      ],
                    ),
                  ),

                  Expanded(child: listaComentarios()),

                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controlador,
                          maxLines: 3,
                          minLines: 1,
                          enabled: !analizando,
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario...',
                            filled: true,
                            fillColor: AppColors.grey100,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                analizando ? null : enviarComentario,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cyan,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                            child: analizando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text(
                                    'Publicar comentario',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

    controlador.dispose();
  }

  // ==========================================
  // PUBLICACIÓN DE EJEMPLO
  // ==========================================

  Widget tarjetaPublicacion({
    required String id,
    required String nombre,
    required String texto,
    String? mediaUrl,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.75),
                        AppColors.purple
                            .withValues(alpha: 0.75),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const Icon(
                  Icons.more_horiz,
                  color: AppColors.grey,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(18),
                color: AppColors.grey100,
              ),
              clipBehavior: Clip.antiAlias,
              child: (mediaUrl == null || mediaUrl.isEmpty)
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.25),
                              AppColors.purple
                                  .withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 55,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    )
                  : FutureBuilder<String>(
                      future: FirebaseStorage.instance
                          .ref(mediaUrl)
                          .getDownloadURL(),
                      builder: (context, urlSnapshot) {
                        if (urlSnapshot.hasData) {
                          return Image.network(
                            urlSnapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) {
                              return _mediaInvalida(color);
                            },
                            loadingBuilder:
                                (context, child, progress) {
                              if (progress == null) {
                                return child;
                              }
                              return Center(
                                child:
                                    CircularProgressIndicator(
                                  color: color,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          );
                        }
                        return _mediaInvalida(color);
                      },
                    ),
            ),

            const SizedBox(height: 12),

            Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.favorite_border,
                  ),
                  color: AppColors.favorite,
                ),

                const Text('0'),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: () => mostrarComentarios(
                    publicacionId: id,
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                  ),
                  color: AppColors.purpleText,
                ),

                const Text('0'),

                const Spacer(),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.bookmark_border,
                  ),
                  color: AppColors.cyanDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaInvalida(Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.25),
            AppColors.purple.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 55,
          color: AppColors.white,
        ),
      ),
    );
  }

  // ==========================================
  // INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final nombre = obtenerNombre();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,

        title: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                AppColors.cyanStrong,
                AppColors.greenStrong,
                AppColors.purple,
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'Lulilu',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 12,
              top: 7,
              bottom: 7,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan,
                  AppColors.green,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: abrirMenuPersonal,
              icon: const Icon(
                Icons.person_outline,
                color: AppColors.white,
              ),
              tooltip: 'Mi cuenta',
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: cargarDatosUsuario,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================
              // PERFIL
              // ==================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.profileBackground1,
                      AppColors.profileBackground2,
                      AppColors.profileBackground3,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cyan,
                            AppColors.purple,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hola 👋',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          if (datosUsuario?['estadoVerificacion'] ==
                              'verificado')
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 15,
                                  color: AppColors.greenStrong,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cuenta verificada',
                                  style: TextStyle(
                                    color: AppColors.grey700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Bienvenido a tu espacio en Lulilu 💗',
                              style: TextStyle(
                                color: AppColors.grey700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ==================================
              // CREAR PUBLICACIÓN
              // ==================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cyan
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cyan,
                            AppColors.purple,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        '¿Qué quieres compartir hoy?',
                        style: TextStyle(
                          color: AppColors.grey,
                        ),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: abrirOpcionesPublicacion,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.cyan,
                        foregroundColor:
                            AppColors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                      ),
                      child: const Text('Crear'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================
              // TOP DE LA SEMANA
              // ==================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.topWeekBackground1,
                      AppColors.topWeekBackground2,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      '⭐',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top de la semana',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Descubre las publicaciones destacadas.',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.purpleDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Publicaciones',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('publicaciones')
                    .where('estadoModeracion', isEqualTo: 'aprobado')
                    .orderBy('fecha', descending: true)
                    .limit(30)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No se pudieron cargar las publicaciones.',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.cyan,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'Aún no hay publicaciones. ¡Sé el primero en compartir! 💗',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  const colores = [
                    AppColors.cyan,
                    AppColors.green,
                    AppColors.purple,
                    AppColors.orange,
                  ];

                  return Column(
                    children: docs.asMap().entries.map((entrada) {
                      final index = entrada.key;
                      final doc = entrada.value;
                      final datos =
                          doc.data() as Map<String, dynamic>;

                      return tarjetaPublicacion(
                        id: doc.id,
                        nombre:
                            datos['nombreAutor'] ?? 'Usuario Lulilu',
                        texto: datos['texto'] ?? '',
                        mediaUrl: datos['mediaUrl'] as String?,
                        color: colores[index % colores.length],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}