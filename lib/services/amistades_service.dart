import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmistadException implements Exception {
  const AmistadException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

class Amistad {
  const Amistad({
    required this.id,
    required this.participantes,
    required this.solicitante,
    required this.destinatario,
    required this.estado,
    required this.claveVoto,
    this.creadoEn,
    this.actualizadoEn,
  });

  final String id;
  final List<String> participantes;
  final String solicitante;
  final String destinatario;
  final String estado;
  final String claveVoto;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  bool get aceptada => estado == 'aceptada';
  bool get pendiente => estado == 'pendiente';
  bool get eliminada => estado == 'eliminada';

  String otraUid(String uid) {
    return participantes.firstWhere(
      (participante) => participante != uid,
      orElse: () => '',
    );
  }

  factory Amistad.desdeDocumento(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data();

    return Amistad(
      id: documento.id,
      participantes:
          (datos['participantes'] as List?)
              ?.map((valor) => valor.toString())
              .toList() ??
          const [],
      solicitante: (datos['solicitante'] ?? '').toString(),
      destinatario: (datos['destinatario'] ?? '').toString(),
      estado: (datos['estado'] ?? 'pendiente').toString(),
      claveVoto: (datos['claveVoto'] ?? '').toString(),
      creadoEn: (datos['creadoEn'] as Timestamp?)?.toDate(),
      actualizadoEn: (datos['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }
}

class AmistadesService {
  const AmistadesService._();

  static String get _uidActual {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      throw const AmistadException('Debes iniciar sesión.');
    }

    return usuario.uid;
  }

  static String idPareja(String primero, String segundo) {
    final ordenados = [primero, segundo]..sort();
    return '${ordenados[0]}--${ordenados[1]}';
  }

  static DocumentReference<Map<String, dynamic>> _referencia(String id) {
    return FirebaseFirestore.instance.collection('amistades').doc(id);
  }

  static Stream<List<Amistad>> streamMias() {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return Stream<List<Amistad>>.value(const []);

    return FirebaseFirestore.instance
        .collection('amistades')
        .where('participantes', arrayContains: usuario.uid)
        .snapshots()
        .map((snapshot) {
          final amistades = snapshot.docs.map(Amistad.desdeDocumento).toList();

          amistades.sort((a, b) {
            final fechaA = a.actualizadoEn ?? a.creadoEn;
            final fechaB = b.actualizadoEn ?? b.creadoEn;

            if (fechaA == null && fechaB == null) return 0;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;

            return fechaB.compareTo(fechaA);
          });

          return amistades;
        });
  }

  static Future<Amistad?> obtenerAmistad(String otraUid) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;

    final snapshot = await _referencia(idPareja(usuario.uid, otraUid)).get();
    if (!snapshot.exists) return null;

    final datos = snapshot.data() ?? <String, dynamic>{};

    return Amistad(
      id: snapshot.id,
      participantes:
          (datos['participantes'] as List?)
              ?.map((valor) => valor.toString())
              .toList() ??
          const [],
      solicitante: (datos['solicitante'] ?? '').toString(),
      destinatario: (datos['destinatario'] ?? '').toString(),
      estado: (datos['estado'] ?? 'pendiente').toString(),
      claveVoto: (datos['claveVoto'] ?? '').toString(),
      creadoEn: (datos['creadoEn'] as Timestamp?)?.toDate(),
      actualizadoEn: (datos['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }

  static Future<void> enviarSolicitud(String destinoUid) async {
    final origenUid = _uidActual;

    if (destinoUid == origenUid) {
      throw const AmistadException('No puedes agregarte a ti mismo.');
    }

    final perfil = await FirebaseFirestore.instance
        .collection('perfilesPublicos')
        .doc(destinoUid)
        .get();

    if (!perfil.exists || perfil.data()?['perfilPublico'] == false) {
      throw const AmistadException(
        'Esta persona no está disponible para recibir solicitudes.',
      );
    }

    final referencia = _referencia(idPareja(origenUid, destinoUid));

    await FirebaseFirestore.instance.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);

      if (actual.exists) {
        final datos = actual.data() ?? <String, dynamic>{};
        final estado = (datos['estado'] ?? '').toString();

        if (estado == 'aceptada') {
          throw const AmistadException('Ya son amigos.');
        }

        if (estado == 'pendiente') {
          if (datos['solicitante'] == origenUid) {
            throw const AmistadException('La solicitud ya fue enviada.');
          }

          throw const AmistadException(
            'Esta persona ya te envió una solicitud. Revísala en Amigos.',
          );
        }
      }

      final claveActual = (actual.data()?['claveVoto'] ?? '').toString();

      transaccion.set(referencia, {
        'participantes': [origenUid, destinoUid],
        'solicitante': origenUid,
        'destinatario': destinoUid,
        'estado': 'pendiente',
        'claveVoto': claveActual.isEmpty ? _generarClave() : claveActual,
        'creadoEn': actual.exists
            ? (actual.data()?['creadoEn'] ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> aceptarSolicitud(String id) async {
    final uid = _uidActual;
    final referencia = _referencia(id);

    await FirebaseFirestore.instance.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);

      if (!actual.exists) {
        throw const AmistadException('La solicitud ya no existe.');
      }

      final datos = actual.data() ?? <String, dynamic>{};

      if (datos['destinatario'] != uid || datos['estado'] != 'pendiente') {
        throw const AmistadException('No puedes aceptar esta solicitud.');
      }

      transaccion.update(referencia, {
        'estado': 'aceptada',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> rechazarSolicitud(String id) async {
    final uid = _uidActual;
    final referencia = _referencia(id);

    await FirebaseFirestore.instance.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);

      if (!actual.exists) return;

      final datos = actual.data() ?? <String, dynamic>{};

      if (datos['destinatario'] != uid || datos['estado'] != 'pendiente') {
        throw const AmistadException('No puedes rechazar esta solicitud.');
      }

      transaccion.update(referencia, {
        'estado': 'rechazada',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> cancelarSolicitud(String id) async {
    final uid = _uidActual;
    final referencia = _referencia(id);

    await FirebaseFirestore.instance.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);

      if (!actual.exists) return;

      final datos = actual.data() ?? <String, dynamic>{};

      if (datos['solicitante'] != uid || datos['estado'] != 'pendiente') {
        throw const AmistadException('No puedes cancelar esta solicitud.');
      }

      transaccion.update(referencia, {
        'estado': 'eliminada',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> eliminarAmistad(String id) async {
    final uid = _uidActual;
    final referencia = _referencia(id);

    await FirebaseFirestore.instance.runTransaction((transaccion) async {
      final actual = await transaccion.get(referencia);

      if (!actual.exists) return;

      final datos = actual.data() ?? <String, dynamic>{};
      final participantes =
          (datos['participantes'] as List?)
              ?.map((valor) => valor.toString())
              .toList() ??
          const <String>[];

      if (!participantes.contains(uid) || datos['estado'] != 'aceptada') {
        throw const AmistadException('No puedes eliminar esta amistad.');
      }

      transaccion.update(referencia, {
        'estado': 'eliminada',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  static String _generarClave() {
    final azar = Random.secure();
    final marca = DateTime.now().microsecondsSinceEpoch;
    final primero = azar.nextInt(1 << 32).toRadixString(36);
    final segundo = azar.nextInt(1 << 32).toRadixString(36);

    return '$marca-$primero$segundo';
  }
}
