import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'backend_service.dart';

class NotificacionesService {
  static Future<void> enviarCorreoBienvenida({
    required String correo,
    required String nombre,
  }) async {
    try {
      await BackendService.enviarCorreo(
        tipo: 'bienvenida',
        destinatario: correo,
        nombre: nombre,
      );
    } catch (e) {
      debugPrint('No se pudo enviar el correo de bienvenida: $e');
    }
  }

  static Future<void> notificarNuevoIngreso() async {
    try {
      final correo = FirebaseAuth.instance.currentUser?.email;

      if (correo == null || correo.isEmpty) return;

      await BackendService.enviarCorreo(
        tipo: 'nuevo_ingreso',
        destinatario: correo,
      );
    } catch (e) {
      debugPrint('No se pudo notificar el nuevo ingreso: $e');
    }
  }
}