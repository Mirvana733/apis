import 'package:flutter_test/flutter_test.dart';
import 'package:lulilu/services/amistades_service.dart';
import 'package:lulilu/services/perfil_publico_service.dart';

void main() {
  group('AmistadesService.idPareja', () {
    test('es estable sin importar el orden de los usuarios', () {
      final primera = AmistadesService.idPareja('uid-b', 'uid-a');
      final segunda = AmistadesService.idPareja('uid-a', 'uid-b');

      expect(primera, segunda);
      expect(primera, 'uid-a--uid-b');
    });

    test('usuarios distintos generan parejas distintas', () {
      expect(
        AmistadesService.idPareja('uid-a', 'uid-b'),
        isNot(AmistadesService.idPareja('uid-a', 'uid-c')),
      );
    });
  });

  group('Amistad', () {
    test('obtiene la otra persona de la pareja', () {
      const amistad = Amistad(
        id: 'uid-a--uid-b',
        participantes: ['uid-a', 'uid-b'],
        solicitante: 'uid-a',
        destinatario: 'uid-b',
        estado: 'aceptada',
        claveVoto: 'clave',
      );

      expect(amistad.otraUid('uid-a'), 'uid-b');
      expect(amistad.otraUid('uid-b'), 'uid-a');
      expect(amistad.aceptada, isTrue);
    });
  });

  group('PerfilPublicoService.normalizarNombre', () {
    test('ignora tildes, mayúsculas y signos', () {
      expect(
        PerfilPublicoService.normalizarNombre('  María José Núñez  '),
        'maria jose nunez',
      );
    });

    test('conserva números y espacios simples', () {
      expect(PerfilPublicoService.normalizarNombre('Ana  2'), 'ana 2');
    });
  });
}
