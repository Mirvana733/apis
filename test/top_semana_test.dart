import 'package:flutter_test/flutter_test.dart';
import 'package:lulilu/services/preferencias_service.dart';
import 'package:lulilu/services/publicacion_service.dart';
import 'package:lulilu/services/top_semana_service.dart';

void main() {
  group('PeriodoSemana', () {
    test('semanaDe ubica el lunes y el domingo a las 00:00', () {
      final periodo = TopSemanaService.semanaDe(DateTime(2026, 10, 14));

      expect(periodo.inicio, DateTime(2026, 10, 12));
      expect(periodo.fin, DateTime(2026, 10, 18));
    });

    test('el periodo dura 6 días (lunes a sábado)', () {
      final periodo = TopSemanaService.semanaDe(DateTime(2026, 10, 14));

      expect(periodo.fin.difference(periodo.inicio), const Duration(days: 6));
    });

    test('semanaDe sobre un lunes conserva ese lunes', () {
      final periodo = TopSemanaService.semanaDe(DateTime(2026, 1, 5));

      expect(periodo.inicio, DateTime(2026, 1, 5));
      expect(periodo.fin, DateTime(2026, 1, 11));
    });

    test('finalizado es falso antes del domingo', () {
      final ahora = DateTime.now();
      final periodo = PeriodoSemana(
        inicio: ahora.subtract(const Duration(days: 1)),
        fin: ahora.add(const Duration(days: 1)),
      );

      expect(periodo.finalizado, isFalse);
    });

    test(
      'el identificador coincide entre cliente y servidor (fecha del lunes)',
      () {
        final periodo = TopSemanaService.semanaDe(DateTime(2026, 10, 14));

        expect(periodo.id, '2026-10-12');
      },
    );

    test('la etiqueta describe el rango dentro del mismo mes', () {
      final periodo = TopSemanaService.semanaDe(DateTime(2026, 10, 14));

      expect(periodo.etiqueta, 'Del 12 al 17 de octubre');
    });

    test('la etiqueta separa los meses cuando cruza de mes', () {
      final periodo = TopSemanaService.semanaDe(DateTime(2026, 4, 30));

      expect(periodo.etiqueta, 'Del 27 de abril al 2 de mayo');
    });

    test('el domingo muestra la semana que acaba de cerrar', () {
      final periodo = TopSemanaService.periodoPublicado(
        ahora: DateTime(2026, 10, 18, 9),
      );

      expect(periodo.inicio, DateTime(2026, 10, 12));
      expect(periodo.fin, DateTime(2026, 10, 18));
    });

    test('el sábado todavía muestra la semana anterior', () {
      final periodo = TopSemanaService.periodoPublicado(
        ahora: DateTime(2026, 10, 17, 22),
      );

      expect(periodo.inicio, DateTime(2026, 10, 5));
    });

    test('el lunes muestra la semana anterior, no la que empieza', () {
      final periodo = TopSemanaService.periodoPublicado(
        ahora: DateTime(2026, 10, 19, 8),
      );

      expect(periodo.inicio, DateTime(2026, 10, 12));
    });

    test('los periodos no se solapan ni dejan hueco de conteo', () {
      final primero = TopSemanaService.semanaDe(DateTime(2026, 10, 14));
      final segundo = TopSemanaService.semanaDe(DateTime(2026, 10, 21));

      expect(
        segundo.inicio.difference(primero.inicio),
        const Duration(days: 7),
      );
      expect(primero.fin.isAfter(segundo.inicio), isFalse);
      expect(primero.fin, DateTime(2026, 10, 18));
      expect(segundo.inicio, DateTime(2026, 10, 19));
    });
  });

  group('PublicacionTop', () {
    test('lee los campos del mapa', () {
      final publicacion = PublicacionTop.desdeMapa('pub-1', {
        'nombreAutor': 'Ana Pérez',
        'texto': 'Hola mundo',
        'mediaUrl': 'publicaciones/u1/foto.jpg',
        'meGusta': 7,
        'comentarios': 3,
      });

      expect(publicacion.id, 'pub-1');
      expect(publicacion.nombreAutor, 'Ana Pérez');
      expect(publicacion.texto, 'Hola mundo');
      expect(publicacion.mediaUrl, 'publicaciones/u1/foto.jpg');
      expect(publicacion.meGusta, 7);
      expect(publicacion.comentarios, 3);
    });

    test('usa valores neutros cuando faltan datos', () {
      final publicacion = PublicacionTop.desdeMapa('pub-2', const {});

      expect(publicacion.nombreAutor, 'Usuario Lulilu');
      expect(publicacion.texto, '');
      expect(publicacion.mediaUrl, '');
      expect(publicacion.meGusta, 0);
      expect(publicacion.comentarios, 0);
    });
  });

  group('PreferenciasPrivacidad: Mostrar mi Top', () {
    test('por defecto es verdadero', () {
      const preferencias = PreferenciasPrivacidad();

      expect(preferencias.mostrarTop, isTrue);
    });

    test('ida y vuelta aMapa/desdeMapa conserva mostrarTop', () {
      const original = PreferenciasPrivacidad(mostrarTop: false);

      final copia = PreferenciasPrivacidad.desdeMapa(original.aMapa());

      expect(copia.mostrarTop, isFalse);
      expect(copia.aMapa()['mostrarTop'], isFalse);
    });

    test('copiarCon cambia solo mostrarTop', () {
      const original = PreferenciasPrivacidad(mostrarTop: true);

      final copia = original.copiarCon(mostrarTop: false);

      expect(copia.mostrarTop, isFalse);
      expect(copia.perfilPublico, original.perfilPublico);
      expect(copia.permitirComentarios, original.permitirComentarios);
    });
  });

  group('cuentaPublicaDe (privacidad reflejada en la publicación)', () {
    test('por defecto la cuenta es pública', () {
      expect(PublicacionService.cuentaPublicaDe(null), isTrue);
      expect(PublicacionService.cuentaPublicaDe({'nombre': 'Ana'}), isTrue);
    });

    test('lee perfilPublico = false desde usuarios/{uid}', () {
      expect(
        PublicacionService.cuentaPublicaDe({
          'preferencias': {
            'privacidad': {'perfilPublico': false},
          },
        }),
        isFalse,
      );
    });

    test('respeta perfilPublico = true', () {
      expect(
        PublicacionService.cuentaPublicaDe({
          'preferencias': {
            'privacidad': {'perfilPublico': true},
          },
        }),
        isTrue,
      );
    });
  });

  group('esPublicacionVisible (filtro del Top público)', () {
    test('incluye una publicación aprobada y de cuenta pública', () {
      expect(
        TopSemanaService.esPublicacionVisible({
          'estadoModeracion': 'aprobado',
          'cuentaPublica': true,
        }),
        isTrue,
      );
    });

    test('excluye cuentas privadas', () {
      expect(
        TopSemanaService.esPublicacionVisible({
          'estadoModeracion': 'aprobado',
          'cuentaPublica': false,
        }),
        isFalse,
      );
    });

    test('excluye publicaciones antiguas sin el campo cuentaPublica', () {
      expect(
        TopSemanaService.esPublicacionVisible({'estadoModeracion': 'aprobado'}),
        isFalse,
      );
    });

    test(
      'excluye publicaciones no aprobadas o con "Mostrar mi Top" apagado',
      () {
        expect(
          TopSemanaService.esPublicacionVisible({
            'estadoModeracion': 'en_revision',
            'cuentaPublica': true,
          }),
          isFalse,
        );
        expect(
          TopSemanaService.esPublicacionVisible({
            'estadoModeracion': 'aprobado',
            'cuentaPublica': true,
            'mostrarEnTop': false,
          }),
          isFalse,
        );
      },
    );
  });
}
