import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'preferencias_service.dart';

/// Periodo de competición del "Top de la semana".
///
/// Va del **lunes a las 00:00** al **domingo a las 00:00** (hora de Bolivia,
/// UTC-4). Es decir, se cuentan las interacciones de lunes a sábado
/// (sábado 23:59:59 inclusive). El domingo es el día en que se publican los
/// resultados y las interacciones de ese día no entran en el conteo.
class PeriodoSemana {
  const PeriodoSemana({required this.inicio, required this.fin});

  /// Duración exacta del periodo: 6 días (lunes 00:00 → domingo 00:00).
  static const Duration duracion = Duration(days: 6);

  /// Lunes a las 00:00 (inclusive).
  final DateTime inicio;

  /// Domingo a las 00:00 (exclusive).
  final DateTime fin;

  /// Identificador estable del periodo: la fecha del lunes (`AAAA-MM-DD`).
  ///
  /// Se eligió la fecha en lugar del número de semana ISO porque así el
  /// cliente (Dart) y el servidor (JavaScript) calculan exactamente el mismo
  /// identificador y nunca se generan resultados duplicados.
  String get id {
    final mes = inicio.month.toString().padLeft(2, '0');
    final dia = inicio.day.toString().padLeft(2, '0');
    return '${inicio.year}-$mes-$dia';
  }

  /// `true` si el periodo ya cerró (llegó el domingo a las 00:00).
  bool get finalizado => !DateTime.now().isBefore(fin);

  String get etiqueta {
    final ultimo = fin.subtract(const Duration(days: 1));

    if (inicio.month == ultimo.month) {
      return 'Del ${inicio.day} al ${ultimo.day} de ${_mes(inicio.month)}';
    }

    return 'Del ${inicio.day} de ${_mes(inicio.month)} '
        'al ${ultimo.day} de ${_mes(ultimo.month)}';
  }

  static const List<String> _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _mes(int numero) => _meses[numero - 1];
}

/// Publicación dentro de un Top semanal.
///
/// [meGusta] y [comentarios] son las interacciones recibidas durante el
/// periodo (o las guardadas en el snapshot del servidor).
class PublicacionTop {
  const PublicacionTop({
    required this.id,
    required this.nombreAutor,
    required this.texto,
    required this.mediaUrl,
    required this.meGusta,
    required this.comentarios,
  });

  final String id;
  final String nombreAutor;
  final String texto;
  final String mediaUrl;
  final int meGusta;
  final int comentarios;

  factory PublicacionTop.desdeMapa(String id, Map<String, dynamic> mapa) {
    return PublicacionTop(
      id: id,
      nombreAutor: (mapa['nombreAutor'] ?? 'Usuario Lulilu').toString(),
      texto: (mapa['texto'] ?? '').toString(),
      mediaUrl: (mapa['mediaUrl'] ?? '').toString(),
      meGusta: (mapa['meGusta'] as num?)?.toInt() ?? 0,
      comentarios: (mapa['comentarios'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> aMapa() => {
    'id': id,
    'nombreAutor': nombreAutor,
    'texto': texto,
    'mediaUrl': mediaUrl,
    'meGusta': meGusta,
    'comentarios': comentarios,
  };
}

/// Resultado del Top de una semana.
///
/// [generado] es `true` cuando proviene de un snapshot guardado por el
/// servidor y `false` cuando se calculó en vivo en el dispositivo.
class ResultadoTopSemana {
  const ResultadoTopSemana({
    required this.periodo,
    required this.topMeGusta,
    required this.topComentarios,
    required this.generado,
  });

  final PeriodoSemana periodo;
  final List<PublicacionTop> topMeGusta;
  final List<PublicacionTop> topComentarios;
  final bool generado;
}

class TopSemanaService {
  /// Cuántas publicaciones se muestran por cada categoría.
  static const int maximo = 10;

  static PeriodoSemana semanaActual() => semanaDe(DateTime.now());

  /// Periodo cuyos resultados se deben mostrar ahora mismo.
  ///
  /// - **Domingo**: el periodo acaba de cerrar, así que se muestran los
  ///   ganadores de esa misma semana (visibles todo el domingo).
  /// - **Lunes a sábado**: se mantienen visibles los resultados de la última
  ///   semana cerrada (el domingo anterior).
  static PeriodoSemana periodoPublicado({DateTime? ahora}) {
    final momento = ahora ?? DateTime.now();
    final semana = semanaDe(momento);

    if (!momento.isBefore(semana.fin)) return semana;

    return _semanaAnterior(semana);
  }

  static PeriodoSemana _semanaAnterior(PeriodoSemana periodo) {
    return PeriodoSemana(
      inicio: periodo.inicio.subtract(const Duration(days: 7)),
      fin: periodo.fin.subtract(const Duration(days: 7)),
    );
  }

  /// Periodo que corresponde a [referencia].
  ///
  /// El inicio es el lunes 00:00 de esa semana; el fin es el domingo 00:00.
  static PeriodoSemana semanaDe(DateTime referencia) {
    final base = DateTime(referencia.year, referencia.month, referencia.day);
    final inicio = base.subtract(Duration(days: base.weekday - 1));

    return PeriodoSemana(
      inicio: inicio,
      fin: inicio.add(PeriodoSemana.duracion),
    );
  }

  /// Escucha el Top oficial de [periodo].
  ///
  /// Si el servidor ya guardó el resultado (domingo), emite ese snapshot
  /// inmutable; si aún no existe, calcula en vivo con la ventana del periodo.
  static Stream<ResultadoTopSemana> streamTopSemana(PeriodoSemana periodo) {
    return FirebaseFirestore.instance
        .collection('topSemanal')
        .doc(periodo.id)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.exists && snapshot.data() != null) {
            return _desdeDocumento(snapshot.data()!, periodo);
          }
          return _calcular(periodo);
        });
  }

  /// Conteo **en vivo** de la semana en curso.
  ///
  /// Se recalcula automáticamente cuando alguien da un Me gusta o comenta,
  /// sin guardar nada: el resultado oficial solo se publica el domingo.
  static Stream<ResultadoTopSemana> streamEnVivo(PeriodoSemana periodo) {
    final db = FirebaseFirestore.instance;
    final inicio = Timestamp.fromDate(periodo.inicio);
    final fin = Timestamp.fromDate(periodo.fin);

    final meGusta = db
        .collection('meGusta')
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThan: fin)
        .snapshots();

    final comentarios = db
        .collection('comentarios')
        .where('estadoModeracion', isEqualTo: 'aprobado')
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThan: fin)
        .snapshots();

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subMeGusta;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subComentarios;
    final controlador = StreamController<ResultadoTopSemana>();

    var docsMeGusta = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var docsComentarios = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var listoMeGusta = false;
    var listoComentarios = false;
    var calculando = false;
    var pendiente = false;

    Future<void> recalcular() async {
      if (!listoMeGusta || !listoComentarios) return;

      if (calculando) {
        pendiente = true;
        return;
      }

      calculando = true;

      do {
        pendiente = false;

        final conteoMeGusta = _contarPorPublicacion(docsMeGusta);
        final conteoComentarios = _contarPorPublicacion(docsComentarios);
        final resultado = await _calcularFinal(
          periodo,
          conteoMeGusta,
          conteoComentarios,
        );

        if (!controlador.isClosed) controlador.add(resultado);
      } while (pendiente);

      calculando = false;
    }

    controlador.onListen = () {
      subMeGusta = meGusta.listen((snapshot) {
        docsMeGusta = snapshot.docs;
        listoMeGusta = true;
        recalcular();
      }, onError: controlador.addError);

      subComentarios = comentarios.listen((snapshot) {
        docsComentarios = snapshot.docs;
        listoComentarios = true;
        recalcular();
      }, onError: controlador.addError);
    };

    controlador.onCancel = () async {
      await subMeGusta?.cancel();
      await subComentarios?.cancel();
    };

    return controlador.stream;
  }

  static Map<String, int> _contarPorPublicacion(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
  ) {
    final conteo = <String, int>{};

    for (final doc in documentos) {
      final id = (doc.data()['publicacionId'] ?? '').toString();
      if (id.isEmpty) continue;
      conteo[id] = (conteo[id] ?? 0) + 1;
    }

    return conteo;
  }

  /// Determina si una publicación puede aparecer en el Top público.
  ///
  /// Falla **cerrado**: una publicación sin el campo `cuentaPublica` **no** se
  /// considera pública. Así una cuenta privada nunca aparece solo porque su
  /// publicación sea antigua.
  static bool esPublicacionVisible(Map<String, dynamic> datos) {
    if (datos['estadoModeracion'] != 'aprobado') return false;
    if (datos['mostrarEnTop'] == false) return false;
    return datos['cuentaPublica'] == true;
  }

  /// Devuelve el Top de [periodo] (por defecto, la semana actual).
  ///
  /// Primero intenta leer el resultado guardado por el servidor. Si aún no
  /// existe (por ejemplo, la semana en curso o el Worker sin desplegar), lo
  /// calcula en vivo a partir de los "Me gusta" y comentarios del periodo.
  static Future<ResultadoTopSemana> obtenerTopSemana({
    PeriodoSemana? periodo,
  }) async {
    final objetivo = periodo ?? semanaActual();

    try {
      final documento = await FirebaseFirestore.instance
          .collection('topSemanal')
          .doc(objetivo.id)
          .get();

      if (documento.exists) {
        return _desdeDocumento(documento.data()!, objetivo);
      }
    } catch (e) {
      debugPrint('No se pudo leer el Top guardado: $e');
    }

    return _calcular(objetivo);
  }

  /// Historial de semanas anteriores, de la más reciente a la más antigua.
  static Future<List<ResultadoTopSemana>> historial({int limite = 12}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('topSemanal')
        .orderBy('generadoEn', descending: true)
        .limit(limite)
        .get();

    return snapshot.docs
        .map((doc) => _desdeDocumento(doc.data(), semanaActual()))
        .toList();
  }

  static ResultadoTopSemana _desdeDocumento(
    Map<String, dynamic> datos,
    PeriodoSemana respaldo,
  ) {
    final inicio = (datos['inicio'] as Timestamp?)?.toDate() ?? respaldo.inicio;
    final fin = (datos['fin'] as Timestamp?)?.toDate() ?? respaldo.fin;

    List<PublicacionTop> parsear(String clave) {
      final lista = datos[clave];

      if (lista is! List) return const [];

      return lista
          .whereType<Map>()
          .map((mapa) {
            final datos = Map<String, dynamic>.from(mapa);
            final id = (datos['id'] ?? datos['publicacionId'] ?? '').toString();
            return PublicacionTop.desdeMapa(id, datos);
          })
          .where((publicacion) => publicacion.id.isNotEmpty)
          .toList();
    }

    return ResultadoTopSemana(
      periodo: PeriodoSemana(inicio: inicio, fin: fin),
      topMeGusta: parsear('topMeGusta'),
      topComentarios: parsear('topComentarios'),
      generado: true,
    );
  }

  static Future<ResultadoTopSemana> _calcular(PeriodoSemana periodo) async {
    final db = FirebaseFirestore.instance;
    final inicio = Timestamp.fromDate(periodo.inicio);
    final fin = Timestamp.fromDate(periodo.fin);

    final conteoMeGusta = <String, int>{};
    final conteoComentarios = <String, int>{};

    try {
      final snapshot = await db
          .collection('meGusta')
          .where('fecha', isGreaterThanOrEqualTo: inicio)
          .where('fecha', isLessThan: fin)
          .get();

      for (final doc in snapshot.docs) {
        final id = (doc.data()['publicacionId'] ?? '').toString();
        if (id.isEmpty) continue;
        conteoMeGusta[id] = (conteoMeGusta[id] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('No se pudieron contar los Me gusta: $e');
    }

    try {
      final snapshot = await db
          .collection('comentarios')
          .where('estadoModeracion', isEqualTo: 'aprobado')
          .where('fecha', isGreaterThanOrEqualTo: inicio)
          .where('fecha', isLessThan: fin)
          .get();

      for (final doc in snapshot.docs) {
        final id = (doc.data()['publicacionId'] ?? '').toString();
        if (id.isEmpty) continue;
        conteoComentarios[id] = (conteoComentarios[id] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('No se pudieron contar los comentarios: $e');
    }

    return _calcularFinal(periodo, conteoMeGusta, conteoComentarios);
  }

  static Future<ResultadoTopSemana> _calcularFinal(
    PeriodoSemana periodo,
    Map<String, int> conteoMeGusta,
    Map<String, int> conteoComentarios,
  ) async {
    final ids = <String>{
      ...conteoMeGusta.keys,
      ...conteoComentarios.keys,
    }.toList();

    final publicaciones = await _obtenerPublicaciones(ids);

    final porId = <String, PublicacionTop>{};

    for (final id in ids) {
      final datos = publicaciones[id];
      if (datos == null) continue;

      porId[id] = PublicacionTop(
        id: id,
        nombreAutor: (datos['nombreAutor'] ?? 'Usuario Lulilu').toString(),
        texto: (datos['texto'] ?? '').toString(),
        mediaUrl: (datos['mediaUrl'] ?? '').toString(),
        meGusta: conteoMeGusta[id] ?? 0,
        comentarios: conteoComentarios[id] ?? 0,
      );
    }

    final topMeGusta = porId.values.where((p) => p.meGusta > 0).toList()
      ..sort((a, b) => b.meGusta.compareTo(a.meGusta));

    final topComentarios = porId.values.where((p) => p.comentarios > 0).toList()
      ..sort((a, b) => b.comentarios.compareTo(a.comentarios));

    return ResultadoTopSemana(
      periodo: periodo,
      topMeGusta: topMeGusta.take(maximo).toList(),
      topComentarios: topComentarios.take(maximo).toList(),
      generado: false,
    );
  }

  static Future<Map<String, Map<String, dynamic>>> _obtenerPublicaciones(
    List<String> ids,
  ) async {
    final resultado = <String, Map<String, dynamic>>{};
    final db = FirebaseFirestore.instance;

    for (var i = 0; i < ids.length; i += 10) {
      final lote = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);

      try {
        final snapshot = await db
            .collection('publicaciones')
            .where(FieldPath.documentId, whereIn: lote)
            .get();

        for (final doc in snapshot.docs) {
          final datos = doc.data();
          if (!esPublicacionVisible(datos)) continue;
          resultado[doc.id] = datos;
        }
      } catch (e) {
        debugPrint('No se pudieron leer las publicaciones del Top: $e');
      }
    }

    return resultado;
  }

  /// Indica si el usuario actual ya dio "Me gusta" a la publicación.
  static Future<bool> usuarioDioMeGusta(String publicacionId) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('meGusta')
          .doc('${publicacionId}_${usuario.uid}')
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('No se pudo leer el Me gusta: $e');
      return false;
    }
  }

  /// Da o quita "Me gusta" y actualiza el contador de la publicación.
  static Future<void> alternarMeGusta({
    required String publicacionId,
    required bool meGusta,
  }) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    final db = FirebaseFirestore.instance;
    final referenciaMeGusta = db
        .collection('meGusta')
        .doc('${publicacionId}_${usuario.uid}');
    final referenciaPublicacion = db
        .collection('publicaciones')
        .doc(publicacionId);

    await db.runTransaction((transaccion) async {
      final snapshotMeGusta = await transaccion.get(referenciaMeGusta);
      final snapshotPublicacion = await transaccion.get(referenciaPublicacion);
      final total =
          (snapshotPublicacion.data()?['totalMeGusta'] as num?)?.toInt() ?? 0;

      if (meGusta) {
        if (!snapshotMeGusta.exists) {
          transaccion.set(referenciaMeGusta, {
            'publicacionId': publicacionId,
            'uidUsuario': usuario.uid,
            'fecha': FieldValue.serverTimestamp(),
          });
          transaccion.update(referenciaPublicacion, {
            'totalMeGusta': total + 1,
          });
        }
      } else {
        if (snapshotMeGusta.exists) {
          transaccion.delete(referenciaMeGusta);
          transaccion.update(referenciaPublicacion, {
            'totalMeGusta': total > 0 ? total - 1 : 0,
          });
        }
      }
    });
  }

  /// Refleja la preferencia "Mostrar mi Top" en las publicaciones del usuario.
  ///
  /// Se guarda en cada publicación (`mostrarEnTop`) porque las reglas de
  /// Firestore no permiten que otros usuarios lean este documento.
  static Future<void> actualizarVisibilidadTop(bool mostrar) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    final db = FirebaseFirestore.instance;
    final snapshot = await db
        .collection('publicaciones')
        .where('uidAutor', isEqualTo: usuario.uid)
        .get();

    if (snapshot.docs.isEmpty) return;

    var lote = db.batch();
    var pendientes = 0;

    for (final doc in snapshot.docs) {
      lote.update(doc.reference, {'mostrarEnTop': mostrar});
      pendientes++;

      if (pendientes == 400) {
        await lote.commit();
        lote = db.batch();
        pendientes = 0;
      }
    }

    if (pendientes > 0) {
      await lote.commit();
    }
  }

  /// Refleja si la cuenta es pública o privada en las publicaciones del
  /// usuario (`cuentaPublica`).
  ///
  /// Se guarda en cada publicación porque las reglas de Firestore no permiten
  /// que otros usuarios lean el documento privado `usuarios/{uid}`. Así una
  /// cuenta privada queda excluida del Top público sin exponer sus datos.
  /// Solo escribe las publicaciones cuyo valor cambió.
  static Future<void> actualizarCuentaPublica(bool cuentaPublica) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    await _sincronizarCampo(usuario.uid, 'cuentaPublica', cuentaPublica);
  }

  /// Sincroniza (sin intervención del usuario) `cuentaPublica` en todas sus
  /// publicaciones con la privacidad real de la cuenta.
  ///
  /// Se llama automáticamente al abrir la app: así las publicaciones antiguas
  /// quedan corregidas sin que el usuario tenga que tocar el interruptor.
  static Future<void> sincronizarCuentaPublica() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    final preferencias = await PreferenciasService.cargarPrivacidad();

    await actualizarCuentaPublica(preferencias.perfilPublico);
  }

  static Future<void> _sincronizarCampo(
    String uid,
    String campo,
    Object valor,
  ) async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db
        .collection('publicaciones')
        .where('uidAutor', isEqualTo: uid)
        .get();

    var lote = db.batch();
    var pendientes = 0;

    for (final doc in snapshot.docs) {
      if (doc.data()[campo] == valor) continue;

      lote.update(doc.reference, {campo: valor});
      pendientes++;

      if (pendientes == 400) {
        await lote.commit();
        lote = db.batch();
        pendientes = 0;
      }
    }

    if (pendientes > 0) {
      await lote.commit();
    }
  }
}
