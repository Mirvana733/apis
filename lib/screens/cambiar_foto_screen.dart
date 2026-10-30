import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/perfil_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/fondo_lulilu.dart';

class CambiarFotoScreen extends StatefulWidget {
  const CambiarFotoScreen({super.key});

  @override
  State<CambiarFotoScreen> createState() => _CambiarFotoScreenState();
}

class _CambiarFotoScreenState extends State<CambiarFotoScreen> {
  final ImagePicker picker = ImagePicker();

  String? fotoActual;
  File? nuevaFoto;

  bool cargando = true;
  bool subiendo = false;

  @override
  void initState() {
    super.initState();
    cargarFotoActual();
  }

  Future<void> cargarFotoActual() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      if (mounted) setState(() => cargando = false);
      return;
    }

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final ruta = documento.data()?['fotoPerfil'];

      if (mounted && ruta is String && ruta.isNotEmpty) {
        setState(() => fotoActual = ruta);
      }
    } catch (e) {
      debugPrint('Error al cargar la foto de perfil: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> elegirFoto(ImageSource origen) async {
    try {
      final XFile? imagen = await picker.pickImage(
        source: origen,
        imageQuality: 82,
        maxWidth: 1200,
      );

      if (imagen == null) return;

      setState(() {
        nuevaFoto = File(imagen.path);
      });
    } catch (e) {
      debugPrint('Error al elegir la foto: $e');
      mostrarMensaje('No se pudo obtener la imagen.');
    }
  }

  Future<void> guardar() async {
    if (nuevaFoto == null) {
      mostrarMensaje('Elige una foto primero.');
      return;
    }

    setState(() => subiendo = true);

    try {
      await PerfilService.subirFotoPerfil(nuevaFoto!);

      if (!mounted) return;

      mostrarMensaje('Foto de perfil actualizada.');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error al subir la foto: $e');

      if (!mounted) return;

      setState(() => subiendo = false);
      mostrarMensaje('No se pudo subir la foto. Inténtalo de nuevo.');
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
          'Cambiar foto',
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
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _vistaPrevia(scheme)),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Tu foto de perfil es visible para otros usuarios y en tus publicaciones.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        onPressed: subiendo
                            ? null
                            : () => elegirFoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('ELEGIR DE LA GALERÍA'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: subiendo
                            ? null
                            : () => elegirFoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('TOMAR FOTO'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: (subiendo || nuevaFoto == null)
                            ? null
                            : guardar,
                        child: subiendo
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: scheme.onSurfaceVariant,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('GUARDAR FOTO'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _vistaPrevia(ColorScheme scheme) {
    const double tamano = 150;

    if (nuevaFoto != null) {
      return ClipOval(
        child: Image.file(
          nuevaFoto!,
          width: tamano,
          height: tamano,
          fit: BoxFit.cover,
        ),
      );
    }

    return AvatarUsuario(
      fotoPerfil: fotoActual,
      size: tamano,
      colorFondo: scheme.primaryContainer,
      colorIcono: scheme.onPrimaryContainer,
    );
  }
}
