import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'backend_service.dart';

class NotificacionesService {
  /// Lee una bandera de `usuarios/{uid}.preferencias.notificaciones`.
  ///
  /// Si no se puede leer (sin usuario o sin conexión) se asume `true` para no
  /// bloquear avisos importantes por un problema de red.
  static Future<bool> _permitido(String clave) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return true;

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final preferencias = documento.data()?['preferencias'];
      if (preferencias is Map) {
        final notificaciones = preferencias['notificaciones'];
        if (notificaciones is Map) {
          if (notificaciones['correosActivos'] == false) return false;
          if (notificaciones[clave] is bool) {
            return notificaciones[clave] as bool;
          }
        }
      }
    } catch (e) {
      debugPrint('No se pudieron leer las preferencias de notificaciones: $e');
    }

    return true;
  }

  static Future<void> enviarCorreoBienvenida({
    required String correo,
    required String nombre,
  }) async {
    if (!await _permitido('correoBienvenida')) return;

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
    if (!await _permitido('avisoNuevoIngreso')) return;

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
