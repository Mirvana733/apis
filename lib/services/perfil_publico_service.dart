import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'preferencias_service.dart';

class PerfilPublico {
  const PerfilPublico({
    required this.uid,
    required this.nombre,
    required this.fotoPerfil,
    required this.perfilPublico,
    required this.mostrarAmigos,
    required this.mostrarVerificacion,
    required this.verificado,
  });

  final String uid;
  final String nombre;
  final String fotoPerfil;
  final bool perfilPublico;
  final bool mostrarAmigos;
  final bool mostrarVerificacion;
  final bool verificado;

  factory PerfilPublico.desdeDocumento(
    DocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data() ?? <String, dynamic>{};

    return PerfilPublico(
      uid: (datos['uid'] ?? documento.id).toString(),
      nombre: (datos['nombre'] ?? 'Usuario Lulilu').toString(),
      fotoPerfil: (datos['fotoPerfil'] ?? '').toString(),
      perfilPublico: datos['perfilPublico'] as bool? ?? true,
      mostrarAmigos: datos['mostrarAmigos'] as bool? ?? true,
      mostrarVerificacion: datos['mostrarVerificacion'] as bool? ?? true,
      verificado: datos['verificado'] as bool? ?? false,
    );
  }
}

class PerfilPublicoService {
  const PerfilPublicoService._();

  static CollectionReference<Map<String, dynamic>> get _coleccion {
    return FirebaseFirestore.instance.collection('perfilesPublicos');
  }

  static Future<void> sincronizarActual() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    final db = FirebaseFirestore.instance;
    final privado = await db.collection('usuarios').doc(usuario.uid).get();
    final datos = privado.data();

    if (datos == null) return;

    final nombre = _nombreCompleto(datos);
    final preferencias = PreferenciasPrivacidad.desdeMapa(
      _mapaPreferencias(datos),
    );
    final foto = (datos['fotoPerfil'] ?? '').toString();

    await _coleccion.doc(usuario.uid).set({
      'uid': usuario.uid,
      'nombre': nombre,
      'nombreNormalizado': normalizarNombre(nombre),
      'fotoPerfil': foto,
      'perfilPublico': preferencias.perfilPublico,
      'mostrarAmigos': preferencias.mostrarAmigos,
      'mostrarVerificacion': preferencias.mostrarVerificacion,
      'verificado': datos['estadoVerificacion'] == 'verificado',
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<PerfilPublico?> streamPerfil(String uid) {
    return _coleccion.doc(uid).snapshots().map((documento) {
      if (!documento.exists) return null;
      return PerfilPublico.desdeDocumento(documento);
    });
  }

  static Future<PerfilPublico?> obtener(String uid) async {
    final documento = await _coleccion.doc(uid).get();
    if (!documento.exists) return null;

    return PerfilPublico.desdeDocumento(documento);
  }

  static Future<List<PerfilPublico>> buscar(String consulta) async {
    final termino = normalizarNombre(consulta);
    final usuario = FirebaseAuth.instance.currentUser;

    if (termino.length < 2) return const [];

    final snapshot = await _coleccion
        .where('perfilPublico', isEqualTo: true)
        .where('nombreNormalizado', isGreaterThanOrEqualTo: termino)
        .where('nombreNormalizado', isLessThan: '$termino\uf8ff')
        .orderBy('nombreNormalizado')
        .limit(20)
        .get();

    return snapshot.docs
        .map(PerfilPublico.desdeDocumento)
        .where((perfil) => perfil.uid != usuario?.uid)
        .toList();
  }

  static Future<Map<String, PerfilPublico>> porUids(
    Iterable<String> uids,
  ) async {
    final unicos = uids.where((uid) => uid.isNotEmpty).toSet().toList();
    final resultado = <String, PerfilPublico>{};

    for (var i = 0; i < unicos.length; i += 10) {
      final finalIndice = (i + 10 > unicos.length) ? unicos.length : i + 10;
      final lote = unicos.sublist(i, finalIndice);
      final snapshot = await _coleccion
          .where(FieldPath.documentId, whereIn: lote)
          .get();

      for (final documento in snapshot.docs) {
        final perfil = PerfilPublico.desdeDocumento(documento);
        resultado[perfil.uid] = perfil;
      }
    }

    return resultado;
  }

  static String normalizarNombre(String valor) {
    const reemplazos = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };

    final minusculas = valor.toLowerCase().trim();
    final buffer = StringBuffer();

    for (final codigo in minusculas.runes) {
      final caracter = String.fromCharCode(codigo);
      final reemplazo = reemplazos[caracter] ?? caracter;
      final esLetraONumero = RegExp(r'^[a-z0-9 ]$').hasMatch(reemplazo);

      if (esLetraONumero) {
        buffer.write(reemplazo);
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _nombreCompleto(Map<String, dynamic> datos) {
    return [datos['nombre'], datos['apellidoPaterno'], datos['apellidoMaterno']]
        .where((valor) => valor != null)
        .map((valor) => valor.toString().trim())
        .where((valor) => valor.isNotEmpty)
        .join(' ');
  }

  static Map<String, dynamic>? _mapaPreferencias(Map<String, dynamic> datos) {
    final preferencias = datos['preferencias'];
    final privacidad = preferencias is Map ? preferencias['privacidad'] : null;

    if (privacidad is Map) {
      return Map<String, dynamic>.from(privacidad);
    }

    return null;
  }
}
