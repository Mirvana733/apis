import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulilu/services/calificaciones_service.dart';
import 'package:lulilu/utils/fecha_bolivia.dart';
import 'package:lulilu/widgets/estrella_lulilu.dart';
import 'package:lulilu/widgets/estrellas_reputacion.dart';

void main() {
  group('FechaBolivia', () {
    test('el día cambia a las 00:00 de Bolivia (04:00 UTC)', () {
      expect(
        FechaBolivia.diaActual(DateTime.utc(2026, 10, 28, 3, 59)),
        DateTime.utc(2026, 10, 27),
      );
      expect(
        FechaBolivia.diaActual(DateTime.utc(2026, 10, 28, 4)),
        DateTime.utc(2026, 10, 28),
      );
    });

    test('el id del día corresponde a la medianoche boliviana', () {
      final id = FechaBolivia.idDia(DateTime.utc(2026, 10, 28, 15));

      expect(id, DateTime.utc(2026, 10, 28, 4).millisecondsSinceEpoch);
      expect(FechaBolivia.esInicioDeDiaBolivia(id), isTrue);
    });
  });

  group('Reputacion', () {
    test('sin votos el promedio real es 0 y el visual es 5', () {
      const reputacion = Reputacion.vacia();

      expect(reputacion.total, 0);
      expect(reputacion.promedio, 0);
      expect(reputacion.promedioVisual, 5);
    });

    test('promedia la calificación más reciente de cada persona', () {
      final reputacion = Reputacion.desdeMapa({
        'votos': {
          'clave-a': {'puntuacion': 5},
          'clave-b': {'puntuacion': 4},
          'clave-c': {'puntuacion': 3},
        },
      });

      expect(reputacion.total, 3);
      expect(reputacion.promedio, 4);
    });

    test('ignora votos inválidos y valores fuera de rango', () {
      final reputacion = Reputacion.desdeMapa({
        'votos': {
          'clave-a': {'puntuacion': 5},
          'clave-b': {'puntuacion': 0},
          'clave-c': {'puntuacion': 9},
          'clave-d': 'texto',
        },
      });

      expect(reputacion.total, 1);
      expect(reputacion.promedio, 5);
    });

    test('conserva la fecha del voto para el historial público', () {
      final fecha = DateTime.utc(2026, 10, 28, 4);
      final reputacion = Reputacion.desdeMapa({
        'votos': {
          'clave-a': {'puntuacion': 5, 'fechaDia': Timestamp.fromDate(fecha)},
        },
      });

      expect(reputacion.votos['clave-a']?.fechaDia?.toUtc(), fecha);
    });
  });

  group('EstrellasReputacion', () {
    testWidgets('sin votos muestra cinco estrellas llenas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EstrellasReputacion(promedio: 0, total: 0, size: 16),
          ),
        ),
      );

      expect(find.byType(EstrellaLulilu), findsNWidgets(5));
    });

    testWidgets('una media estrella se dibuja de forma parcial', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EstrellasReputacion(promedio: 3.5, total: 1, size: 16),
          ),
        ),
      );

      expect(find.byType(EstrellaLulilu), findsNWidgets(6));
      expect(find.byType(ClipRect), findsOneWidget);
    });
  });
}
