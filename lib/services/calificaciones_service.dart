import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/fecha_bolivia.dart';
import 'amistades_service.dart';

class CalificacionException implements Exception {
  const CalificacionException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

class VotoPublico {
  const VotoPublico({
    required this.puntuacion,
    required this.fechaDia,
    this.actualizadoEn,
  });

  final int puntuacion;
  final DateTime? fechaDia;
  final DateTime? actualizadoEn;

  factory VotoPublico.desdeMapa(Map<String, dynamic> mapa) {
    return VotoPublico(
      puntuacion: (mapa['puntuacion'] as num?)?.toInt() ?? 0,
      fechaDia: (mapa['fechaDia'] as Timestamp?)?.toDate(),
      actualizadoEn: (mapa['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }
}

class Reputacion {
  const Reputacion({
    required this.promedio,
    required this.total,
    required this.votos,
  });

  const Reputacion.vacia()
    : promedio = 0,
      total = 0,
      votos = const <String, VotoPublico>{};

  final double promedio;
  final int total;
  final Map<String, VotoPublico> votos;

  double get promedioVisual => total == 0 ? 5 : promedio;

  factory Reputacion.desdeMapa(Map<String, dynamic>? mapa) {
    final votosRaw = mapa?['votos'];

    if (votosRaw is! Map) {
      return const Reputacion.vacia();
    }

    final votos = <String, VotoPublico>{};
    var suma = 0;

    for (final entrada in votosRaw.entries) {
      if (entrada.value is! Map) continue;

      final voto = VotoPublico.desdeMapa(
        Map<String, dynamic>.from(entrada.value as Map),
      );

      if (voto.puntuacion < 1 || voto.puntuacion > 5) continue;

      votos[entrada.key.toString()] = voto;
      suma += voto.puntuacion;
    }

    if (votos.isEmpty) {
      return const Reputacion.vacia();
    }

    return Reputacion(
      promedio: suma / votos.length,
      total: votos.length,
      votos: votos,
    );
  }
}

class CalificacionesService {
  const CalificacionesService._();

  static String get _uidActual {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      throw const CalificacionException('Debes iniciar sesión.');
    }

    return usuario.uid;
  }

  static DocumentReference<Map<String, dynamic>> _reputacionRef(String uid) {
    return FirebaseFirestore.instance
        .collection('reputacionesPublicas')
        .doc(uid);
  }

  static DocumentReference<Map<String, dynamic>> _votoRef(
    String calificadoUid,
    String calificadorUid,
  ) {
    return FirebaseFirestore.instance
        .collection('calificaciones')
        .doc(calificadoUid)
        .collection('votos')
        .doc(calificadorUid);
  }

  static DocumentReference<Map<String, dynamic>> _historialRef(
    String calificadoUid,
    String calificadorUid,
    int idDia,
  ) {
    return _votoRef(
      calificadoUid,
      calificadorUid,
    ).collection('historial').doc('$idDia');
  }

  static Stream<Reputacion> streamReputacion(String uid) {
    return _reputacionRef(uid)
        .snapshots()
        .map((snapshot) => Reputacion.desdeMapa(snapshot.data()));
  }

  static Future<Reputacion> obtenerReputacion(String uid) async {
    final snapshot = await _reputacionRef(uid).get();
    return Reputacion.desdeMapa(snapshot.data());
  }

  static Stream<int?> streamMiVoto(String calificadoUid) {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return Stream<int?>.value(null);

    return _votoRef(calificadoUid, usuario.uid).snapshots().map((snapshot) {
      return (snapshot.data()?['puntuacion'] as num?)?.toInt();
    });
  }

  static Future<int?> obtenerMiVoto(String calificadoUid) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;

    final snapshot = await _votoRef(calificadoUid, usuario.uid).get();
    return (snapshot.data()?['puntuacion'] as num?)?.toInt();
  }

  static Future<void> calificar({
    required String calificadoUid,
    required int puntuacion,
  }) async {
    final calificadorUid = _uidActual;

    if (calificadoUid == calificadorUid) {
      throw const CalificacionException('No puedes calificarte a ti mismo.');
    }

    if (puntuacion < 1 || puntuacion > 5) {
      throw const CalificacionException('Elige entre 1 y 5 estrellas.');
    }

    final db = FirebaseFirestore.instance;
    final amistadRef = db
        .collection('amistades')
        .doc(AmistadesService.idPareja(calificadorUid, calificadoUid));
    final reputacionRef = _reputacionRef(calificadoUid);
    final votoRef = _votoRef(calificadoUid, calificadorUid);
    final dia = FechaBolivia.diaActual();
    final idDia = FechaBolivia.idDia();
    final fechaDia = Timestamp.fromDate(FechaBolivia.inicioDia(dia));

    await db.runTransaction((transaccion) async {
      final amistad = await transaccion.get(amistadRef);

      if (!amistad.exists) {
        throw const CalificacionException(
          'Solo puedes calificar a personas aceptadas como amigos.',
        );
      }

      final datosAmistad = amistad.data() ?? <String, dynamic>{};
      final participantes = (datosAmistad['participantes'] as List?)
          ?.map((valor) => valor.toString())
          .toList();

      if (datosAmistad['estado'] != 'aceptada' ||
          participantes == null ||
          !participantes.contains(calificadorUid) ||
          !participantes.contains(calificadoUid)) {
        throw const CalificacionException(
          'Solo puedes calificar a personas aceptadas como amigos.',
        );
      }

      var claveVoto = (datosAmistad['claveVoto'] ?? '').toString();

      if (claveVoto.isEmpty) {
        claveVoto = _generarClave();
        transaccion.update(amistadRef, {
          'claveVoto': claveVoto,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      }

      final publica = await transaccion.get(reputacionRef);
      final votos = Map<String, dynamic>.from(
        (publica.data()?['votos'] as Map?) ?? const <String, dynamic>{},
      );

      votos[claveVoto] = {
        'puntuacion': puntuacion,
        'fechaDia': fechaDia,
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

      final historialRef = _historialRef(calificadoUid, calificadorUid, idDia);

      transaccion.set(votoRef, {
        'calificadorUid': calificadorUid,
        'calificadoUid': calificadoUid,
        'puntuacion': puntuacion,
        'fechaDia': fechaDia,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      transaccion.set(historialRef, {
        'puntuacion': puntuacion,
        'fechaDia': fechaDia,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      transaccion.set(reputacionRef, {
        'uid': calificadoUid,
        'votos': votos,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<List<Map<String, dynamic>>> historial(
    String calificadoUid,
  ) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return const [];

    final snapshot = await _votoRef(
      calificadoUid,
      usuario.uid,
    ).collection('historial').orderBy('fechaDia', descending: true).get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static String _generarClave() {
    final azar = Random.secure();
    final marca = DateTime.now().microsecondsSinceEpoch;
    final primero = azar.nextInt(1 << 32).toRadixString(36);
    final segundo = azar.nextInt(1 << 32).toRadixString(36);

    return '$marca-$primero$segundo';
  }
}
