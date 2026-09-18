import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../utils/archivos_media.dart';
import '../utils/moderacion_local.dart';
import 'backend_service.dart';

class ResultadoPublicacion {
  final String estado;
  final String mensaje;

  const ResultadoPublicacion({required this.estado, required this.mensaje});
}

class PublicacionService {
  static Future<ResultadoPublicacion> publicarTexto(String texto) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      return const ResultadoPublicacion(
        estado: 'error',
        mensaje: 'Inicia sesión para publicar.',
      );
    }

    final ofensiva = palabraOfensiva(texto);

    if (ofensiva != null) {
      return ResultadoPublicacion(
        estado: 'bloqueado',
        mensaje:
            'No se puede subir este contenido porque contiene una palabra ofensiva.',
      );
    }

    try {
      final resultado = await BackendService.moderarTexto(
        tipo: 'texto',
        texto: texto,
      );

      final aprobado = resultado['aprobado'] == true;

      if (!aprobado) {
        final motivo = (resultado['motivo'] ?? '') as String;

        return ResultadoPublicacion(
          estado: 'bloqueado',
          mensaje: motivo.isEmpty
              ? 'No se puede subir este contenido porque es inapropiado.'
              : 'No se puede subir este contenido: $motivo',
        );
      }

      await _guardarPublicacionTexto(usuario, texto);

      return const ResultadoPublicacion(
        estado: 'aprobado',
        mensaje: '¡Tu texto fue publicado! 💗',
      );
    } catch (e) {
      debugPrint('Error al publicar texto: $e');

      return const ResultadoPublicacion(
        estado: 'error',
        mensaje: 'No se pudo publicar el texto. Inténtalo de nuevo.',
      );
    }
  }

  static Future<void> _guardarPublicacionTexto(
    User usuario,
    String texto,
  ) async {
    final documentoUsuario = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .get();

    final datosUsuario = documentoUsuario.exists
        ? documentoUsuario.data()
        : <String, dynamic>{};

    final nombreAutor = [
      datosUsuario?['nombre'],
      datosUsuario?['apellidoPaterno'],
    ].whereType<String>().where((valor) => valor.trim().isNotEmpty).join(' ').trim();

    await FirebaseFirestore.instance.collection('publicaciones').add({
      'uidAutor': usuario.uid,
      'nombreAutor': nombreAutor.isEmpty ? 'Usuario Lulilu' : nombreAutor,
      'tipo': 'texto',
      'texto': texto,
      'mediaUrl': '',
      'estadoModeracion': 'aprobado',
      'resultadoModeracion': {'proveedor': 'gemini-worker'},
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  static Future<ResultadoPublicacion> publicarImagen(File imagen) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      return const ResultadoPublicacion(
        estado: 'error',
        mensaje: 'Inicia sesión para publicar.',
      );
    }

    final callable = FirebaseFunctions.instance.httpsCallable('crearPublicacion');
    final respuesta = await callable.call({'tipo': 'imagen'});
    final data = Map<String, dynamic>.from(respuesta.data as Map);
    final id = data['id'] as String;

    final extension = extensionMedia(imagen);
    final contentType = contentTypeMedia(imagen);
    final ruta = 'publicaciones/${usuario.uid}/$id$extension';

    final ref = FirebaseStorage.instance.ref(ruta);
    await ref.putFile(
      imagen,
      SettableMetadata(contentType: contentType),
    );

    return _esperarVeredicto(id, 'imagen');
  }

  static Future<ResultadoPublicacion> publicarVideo(File video) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      return const ResultadoPublicacion(
        estado: 'error',
        mensaje: 'Inicia sesión para publicar.',
      );
    }

    final callable = FirebaseFunctions.instance.httpsCallable('crearPublicacion');
    final respuesta = await callable.call({'tipo': 'video'});
    final data = Map<String, dynamic>.from(respuesta.data as Map);
    final id = data['id'] as String;

    final extension = video.path.toLowerCase().endsWith('.mov')
        ? '.mov'
        : '.mp4';
    final contentType = extension == '.mov' ? 'video/quicktime' : 'video/mp4';
    final ruta = 'publicaciones/${usuario.uid}/$id$extension';

    final ref = FirebaseStorage.instance.ref(ruta);
    await ref.putFile(
      video,
      SettableMetadata(contentType: contentType),
    );

    return _esperarVeredicto(id, 'video');
  }

  static Future<ResultadoPublicacion> publicarAudio(
    File audio, {
    String? extensionAudio,
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      return const ResultadoPublicacion(
        estado: 'error',
        mensaje: 'Inicia sesión para publicar.',
      );
    }

    final callable = FirebaseFunctions.instance.httpsCallable('crearPublicacion');
    final respuesta = await callable.call({'tipo': 'audio'});
    final data = Map<String, dynamic>.from(respuesta.data as Map);
    final id = data['id'] as String;

    final extensionFinal = (extensionAudio?.toLowerCase() ?? 'mp3');
    final ruta = 'publicaciones/${usuario.uid}/$id.$extensionFinal';
    final contentType = _contentTypeAudio(extensionFinal);

    final ref = FirebaseStorage.instance.ref(ruta);
    await ref.putFile(
      audio,
      SettableMetadata(contentType: contentType),
    );

    return _esperarVeredicto(id, 'audio');
  }

  static String _contentTypeAudio(String extension) {
    switch (extension) {
      case 'm4a':
      case 'mp4':
        return 'audio/mp4';
      case 'ogg':
      case 'oga':
        return 'audio/ogg';
      case 'wav':
        return 'audio/wav';
      case 'webm':
        return 'audio/webm';
      default:
        return 'audio/mpeg';
    }
  }

  static Future<ResultadoPublicacion> _esperarVeredicto(
    String id,
    String tipo,
  ) async {
    try {
      final datos = await FirebaseFirestore.instance
          .doc('publicaciones/$id')
          .snapshots()
          .map((snap) => snap.data())
          .firstWhere(
            (datos) =>
                datos != null && datos['estadoModeracion'] != 'en_revision',
          )
          .timeout(const Duration(seconds: 40));

      final estado = datos?['estadoModeracion'] as String?;
      final motivo = (datos?['motivo'] ?? '') as String;

      switch (estado) {
        case 'aprobado':
          return ResultadoPublicacion(
            estado: 'aprobado',
            mensaje: 'Tu $tipo fue publicado.',
          );
        case 'bloqueado':
          return ResultadoPublicacion(
            estado: 'bloqueado',
            mensaje: 'Tu $tipo no puede publicarse porque contiene contenido inapropiado.',
          );
        default:
          return ResultadoPublicacion(
            estado: 'rechazado',
            mensaje: motivo.isEmpty
                ? 'Tu $tipo fue rechazado.'
                : 'Tu $tipo fue rechazado: $motivo',
          );
      }
    } on TimeoutException {
      return ResultadoPublicacion(
        estado: 'revision',
        mensaje: 'Tu $tipo sigue en revisión. Se publicará o reportará pronto.',
      );
    }
  }
}