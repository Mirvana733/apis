import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../utils/archivos_media.dart';
import 'perfil_publico_service.dart';

/// Lectura y escritura de los datos editables del perfil.
///
/// Reutiliza el documento `usuarios/{uid}` que ya crea el registro. La regla
/// `allow write: if esDueno(uid)` permite al usuario actualizar solo su doc.
class PerfilService {
  static Future<void> actualizarPerfil({
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String numero,
    required DateTime fechaNacimiento,
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .update({
          'nombre': nombre.trim(),
          'apellidoPaterno': apellidoPaterno.trim(),
          'apellidoMaterno': apellidoMaterno.trim(),
          'numero': numero.trim(),
          'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
        });

    await PerfilPublicoService.sincronizarActual();
  }

  /// Sube la foto de perfil a `usuarios/{uid}/avatar.<ext>` (una sola carpeta,
  /// que es lo que permite la regla actual de Storage) y guarda la ruta en el
  /// documento del usuario.
  static Future<String> subirFotoPerfil(File imagen) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    final extension = extensionMedia(imagen);
    final ruta = 'usuarios/${usuario.uid}/avatar$extension';
    final ref = FirebaseStorage.instance.ref(ruta);

    await ref.putFile(
      imagen,
      SettableMetadata(contentType: contentTypeMedia(imagen)),
    );

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .update({'fotoPerfil': ruta});

    await PerfilPublicoService.sincronizarActual();

    return ruta;
  }
}
