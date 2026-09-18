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
      debugPrint('Función eliminarCuenta no disponible, se elimina localmente: $e');
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

    await db
        .collection('verificaciones')
        .doc(uid)
        .delete()
        .catchError((_) {});
    await db
        .collection('usuarios')
        .doc(uid)
        .delete()
        .catchError((_) {});
  }

  static Future<void> _eliminarCuentaAuth() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    await usuario.delete();
  }
}