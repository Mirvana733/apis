import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/moderacion_local.dart';
import 'backend_service.dart';

class ModeracionService {
  static Future<ResultadoComentario> publicarComentario(
    String texto, {
    String? publicacionId,
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const ResultadoComentario(
        aprobado: false,
        motivo: 'Inicia sesión para comentar.',
      );
    }

    final ofensiva = palabraOfensiva(texto);

    if (ofensiva != null) {
      return const ResultadoComentario(
        aprobado: false,
        motivo: 'Tu comentario contiene una palabra ofensiva.',
      );
    }

    final resultado = await BackendService.moderarTexto(
      tipo: 'comentario',
      texto: texto,
    );

    final aprobado = resultado['aprobado'] == true;

    if (!aprobado) {
      return ResultadoComentario(
        aprobado: false,
        motivo: (resultado['motivo'] as String?) ?? 'Contenido inapropiado',
      );
    }

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

    final referencia = await FirebaseFirestore.instance
        .collection('comentarios')
        .add({
      'uidUsuario': usuario.uid,
      'publicacionId': publicacionId,
      'nombreAutor': nombreAutor.isEmpty
          ? 'Usuario Lulilu'
          : nombreAutor,
      'texto': texto,
      'estadoModeracion': 'aprobado',
      'fecha': FieldValue.serverTimestamp(),
    });

    return ResultadoComentario(
      aprobado: true,
      motivo: null,
      id: referencia.id,
    );
  }
}

class ResultadoComentario {
  const ResultadoComentario({
    required this.aprobado,
    this.motivo,
    this.id,
  });

  final bool aprobado;
  final String? motivo;
  final String? id;
}