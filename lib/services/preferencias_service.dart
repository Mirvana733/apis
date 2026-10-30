import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Preferencias de privacidad del usuario.
///
/// Se guardan dentro del documento existente `usuarios/{uid}`, en el campo
/// `preferencias.privacidad`. No se crean colecciones nuevas.
class PreferenciasPrivacidad {
  const PreferenciasPrivacidad({
    this.perfilPublico = true,
    this.permitirComentarios = true,
    this.mostrarNumero = false,
    this.mostrarFechaNacimiento = false,
    this.mostrarAmigos = true,
    this.mostrarVerificacion = true,
    this.mostrarTop = true,
  });

  final bool perfilPublico;
  final bool permitirComentarios;
  final bool mostrarNumero;
  final bool mostrarFechaNacimiento;
  final bool mostrarAmigos;
  final bool mostrarVerificacion;

  /// Cuando es `false`, las publicaciones del usuario se excluyen del
  /// "Top de la semana". Se refleja en el campo `mostrarEnTop` de cada
  /// publicación para que otros usuarios puedan filtrarlo aunque no
  /// puedan leer este documento.
  final bool mostrarTop;

  factory PreferenciasPrivacidad.desdeMapa(Map<String, dynamic>? mapa) {
    if (mapa == null) {
      return const PreferenciasPrivacidad();
    }

    return PreferenciasPrivacidad(
      perfilPublico: mapa['perfilPublico'] as bool? ?? true,
      permitirComentarios: mapa['permitirComentarios'] as bool? ?? true,
      mostrarNumero: mapa['mostrarNumero'] as bool? ?? false,
      mostrarFechaNacimiento: mapa['mostrarFechaNacimiento'] as bool? ?? false,
      mostrarAmigos: mapa['mostrarAmigos'] as bool? ?? true,
      mostrarVerificacion: mapa['mostrarVerificacion'] as bool? ?? true,
      mostrarTop: mapa['mostrarTop'] as bool? ?? true,
    );
  }

  Map<String, dynamic> aMapa() => {
    'perfilPublico': perfilPublico,
    'permitirComentarios': permitirComentarios,
    'mostrarNumero': mostrarNumero,
    'mostrarFechaNacimiento': mostrarFechaNacimiento,
    'mostrarAmigos': mostrarAmigos,
    'mostrarVerificacion': mostrarVerificacion,
    'mostrarTop': mostrarTop,
  };

  PreferenciasPrivacidad copiarCon({
    bool? perfilPublico,
    bool? permitirComentarios,
    bool? mostrarNumero,
    bool? mostrarFechaNacimiento,
    bool? mostrarAmigos,
    bool? mostrarVerificacion,
    bool? mostrarTop,
  }) {
    return PreferenciasPrivacidad(
      perfilPublico: perfilPublico ?? this.perfilPublico,
      permitirComentarios: permitirComentarios ?? this.permitirComentarios,
      mostrarNumero: mostrarNumero ?? this.mostrarNumero,
      mostrarFechaNacimiento:
          mostrarFechaNacimiento ?? this.mostrarFechaNacimiento,
      mostrarAmigos: mostrarAmigos ?? this.mostrarAmigos,
      mostrarVerificacion: mostrarVerificacion ?? this.mostrarVerificacion,
      mostrarTop: mostrarTop ?? this.mostrarTop,
    );
  }
}

/// Preferencias de notificaciones.
///
/// La app solo envía dos correos reales (bienvenida e inicio de sesión en un
/// dispositivo nuevo). Estas banderas controlan si se envían.
class PreferenciasNotificaciones {
  const PreferenciasNotificaciones({
    this.correosActivos = true,
    this.correoBienvenida = true,
    this.avisoNuevoIngreso = true,
  });

  final bool correosActivos;
  final bool correoBienvenida;
  final bool avisoNuevoIngreso;

  factory PreferenciasNotificaciones.desdeMapa(Map<String, dynamic>? mapa) {
    if (mapa == null) {
      return const PreferenciasNotificaciones();
    }

    return PreferenciasNotificaciones(
      correosActivos: mapa['correosActivos'] as bool? ?? true,
      correoBienvenida: mapa['correoBienvenida'] as bool? ?? true,
      avisoNuevoIngreso: mapa['avisoNuevoIngreso'] as bool? ?? true,
    );
  }

  Map<String, dynamic> aMapa() => {
    'correosActivos': correosActivos,
    'correoBienvenida': correoBienvenida,
    'avisoNuevoIngreso': avisoNuevoIngreso,
  };

  PreferenciasNotificaciones copiarCon({
    bool? correosActivos,
    bool? correoBienvenida,
    bool? avisoNuevoIngreso,
  }) {
    return PreferenciasNotificaciones(
      correosActivos: correosActivos ?? this.correosActivos,
      correoBienvenida: correoBienvenida ?? this.correoBienvenida,
      avisoNuevoIngreso: avisoNuevoIngreso ?? this.avisoNuevoIngreso,
    );
  }
}

class PreferenciasService {
  static Future<Map<String, dynamic>?> _leerPreferencias() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;

    final documento = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .get();

    final datos = documento.data();
    final preferencias = datos?['preferencias'];

    if (preferencias is Map) {
      return Map<String, dynamic>.from(preferencias);
    }

    return null;
  }

  static Future<PreferenciasPrivacidad> cargarPrivacidad() async {
    final preferencias = await _leerPreferencias();
    final privacidad = preferencias?['privacidad'];

    return PreferenciasPrivacidad.desdeMapa(
      privacidad is Map ? Map<String, dynamic>.from(privacidad) : null,
    );
  }

  static Future<void> guardarPrivacidad(PreferenciasPrivacidad valores) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .update({'preferencias.privacidad': valores.aMapa()});
  }

  static Future<PreferenciasNotificaciones> cargarNotificaciones() async {
    final preferencias = await _leerPreferencias();
    final notificaciones = preferencias?['notificaciones'];

    return PreferenciasNotificaciones.desdeMapa(
      notificaciones is Map ? Map<String, dynamic>.from(notificaciones) : null,
    );
  }

  static Future<void> guardarNotificaciones(
    PreferenciasNotificaciones valores,
  ) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión.');
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .update({'preferencias.notificaciones': valores.aMapa()});
  }
}
