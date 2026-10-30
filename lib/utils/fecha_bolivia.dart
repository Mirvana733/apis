import 'package:cloud_firestore/cloud_firestore.dart';

class FechaBolivia {
  const FechaBolivia._();

  static const Duration desfase = Duration(hours: -4);
  static const int milisegundosDelDia = 86400000;

  static DateTime diaActual([DateTime? ahora]) {
    final instante = (ahora ?? DateTime.now()).toUtc().add(desfase);

    return DateTime.utc(instante.year, instante.month, instante.day);
  }

  static DateTime inicioDia(DateTime dia) {
    return DateTime.utc(dia.year, dia.month, dia.day, 4);
  }

  static int idDia([DateTime? ahora]) {
    return inicioDia(diaActual(ahora)).millisecondsSinceEpoch;
  }

  static Timestamp timestampDia([DateTime? ahora]) {
    return Timestamp.fromDate(inicioDia(diaActual(ahora)));
  }

  static bool esInicioDeDiaBolivia(int milisegundos) {
    return milisegundos % milisegundosDelDia == 14400000;
  }
}
