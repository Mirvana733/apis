import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class CuentaService {
  static Future<void> eliminarCuenta() async {
    try {
      await FirebaseFunctions.instance.httpsCallable('eliminarCuenta').call();
      return;
    } catch (e) {
      debugPrint(
        'Función eliminarCuenta no disponible, se elimina localmente: $e',
      );
    }

    await _eliminarArchivosStorage();
    await _eliminarDatosFirestore();
    await _eliminarCuentaAuth();
  }

  static Future<void> _eliminarArchivosStorage() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    final storage = FirebaseStorage.instance;
    final uid = usuario.uid;

    for (final prefijo in ['usuarios/$uid/', 'publicaciones/$uid/']) {
      try {
        final lista = await storage.ref(prefijo).listAll();

        for (final elemento in lista.items) {
          await elemento.delete().catchError((_) {});
        }
      } catch (e) {
        debugPrint('No se pudo listar $prefijo: $e');
      }
    }
  }

  static Future<void> _eliminarDatosFirestore() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    final db = FirebaseFirestore.instance;
    final uid = usuario.uid;

    final publicaciones = await db
        .collection('publicaciones')
        .where('uidAutor', isEqualTo: uid)
        .get();
    for (final doc in publicaciones.docs) {
      await doc.reference.delete();
    }

    final comentarios = await db
        .collection('comentarios')
        .where('uidUsuario', isEqualTo: uid)
        .get();
    for (final doc in comentarios.docs) {
      await doc.reference.delete();
    }

    await _eliminarAmistadesYCalificaciones(uid);

    try {
      await db.collection('reputacionesPublicas').doc(uid).delete();
    } catch (_) {}

    try {
      await db.collection('perfilesPublicos').doc(uid).delete();
    } catch (_) {}

    await db.collection('verificaciones').doc(uid).delete().catchError((_) {});
    await db.collection('usuarios').doc(uid).delete().catchError((_) {});
  }

  static Future<void> _eliminarAmistadesYCalificaciones(String uid) async {
    final db = FirebaseFirestore.instance;

    try {
      final amistades = await db
          .collection('amistades')
          .where('participantes', arrayContains: uid)
          .get();

      for (final amistad in amistades.docs) {
        final datos = amistad.data();
        final participantes =
            (datos['participantes'] as List?)
                ?.map((valor) => valor.toString())
                .toList() ??
            const <String>[];
        final otroUid = participantes.firstWhere(
          (participante) => participante != uid,
          orElse: () => '',
        );

        if (otroUid.isEmpty) continue;

        await _eliminarVotosEnviados(otroUid, uid);
        await _quitarVotoPublico(
          otroUid,
          (datos['claveVoto'] ?? '').toString(),
        );
        await amistad.reference.delete();
      }
    } catch (e) {
      debugPrint('No se pudieron limpiar las amistades: $e');
    }
  }

  static Future<void> _eliminarVotosEnviados(
    String calificadoUid,
    String calificadorUid,
  ) async {
    final db = FirebaseFirestore.instance;

    try {
      final voto = db
          .collection('calificaciones')
          .doc(calificadoUid)
          .collection('votos')
          .doc(calificadorUid);
      final historial = await voto.collection('historial').get();

      for (final registro in historial.docs) {
        await registro.reference.delete();
      }

      await voto.delete();
    } catch (e) {
      debugPrint('No se pudo borrar una calificación enviada: $e');
    }
  }

  static Future<void> _quitarVotoPublico(
    String calificadoUid,
    String claveVoto,
  ) async {
    if (claveVoto.isEmpty) return;

    try {
      final db = FirebaseFirestore.instance;
      final referencia = db
          .collection('reputacionesPublicas')
          .doc(calificadoUid);
      final documento = await referencia.get();
      final votosRaw = documento.data()?['votos'];

      if (votosRaw is! Map) return;

      final votos = Map<String, dynamic>.from(votosRaw);
      votos.remove(claveVoto);

      await referencia.update({
        'votos': votos,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('No se pudo limpiar el voto público: $e');
    }
  }

  static Future<void> _eliminarCuentaAuth() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    await usuario.delete();
  }
}
