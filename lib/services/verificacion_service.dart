import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../utils/archivos_media.dart';

class ResultadoVerificacion {
  final bool aprobado;
  final String mensaje;

  const ResultadoVerificacion({
    required this.aprobado,
    required this.mensaje,
  });
}

class VerificacionService {
  static Future<ResultadoVerificacion> verificar({
    required File fotoCI,
    required File selfie,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required DateTime fechaNacimiento,
    required String numero,
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      return const ResultadoVerificacion(
        aprobado: false,
        mensaje: 'Inicia sesión para verificar tu identidad.',
      );
    }

    final uid = usuario.uid;

    final rutaCI = 'usuarios/$uid/identidad/fotoCI${extensionMedia(fotoCI)}';
    final rutaSelfie = 'usuarios/$uid/identidad/selfie${extensionMedia(selfie)}';

    await FirebaseStorage.instance.ref(rutaCI).putFile(
          fotoCI,
          SettableMetadata(contentType: contentTypeMedia(fotoCI)),
        );

    await FirebaseStorage.instance.ref(rutaSelfie).putFile(
          selfie,
          SettableMetadata(contentType: contentTypeMedia(selfie)),
        );

    final callable = FirebaseFunctions.instance.httpsCallable('verificarIdentidad');

    final respuesta = await callable.call({
      'nombre': nombre,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'fechaNacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'numero': numero,
      'fotoCI': rutaCI,
      'selfie': rutaSelfie,
    });

    final data = Map<String, dynamic>.from(respuesta.data as Map);
    final aprobado = data['aprobado'] == true;

    return ResultadoVerificacion(
      aprobado: aprobado,
      mensaje: aprobado
          ? '¡Identidad verificada! Tu cuenta queda confirmada.'
          : 'No se pudo verificar tu identidad. Revisa que el número de tu CI y que la selfie coincida con la foto del documento.',
    );
  }
}