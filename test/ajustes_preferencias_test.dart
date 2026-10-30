import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulilu/screens/configuracion_screen.dart';
import 'package:lulilu/services/preferencias_service.dart';
import 'package:lulilu/theme/app_ajustes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppAjustes.instancia.cargar();
  });

  group('PreferenciasPrivacidad', () {
    test('valores por defecto', () {
      const p = PreferenciasPrivacidad();

      expect(p.perfilPublico, isTrue);
      expect(p.permitirComentarios, isTrue);
      expect(p.mostrarNumero, isFalse);
      expect(p.mostrarFechaNacimiento, isFalse);
      expect(p.mostrarAmigos, isTrue);
      expect(p.mostrarVerificacion, isTrue);
      expect(p.mostrarTop, isTrue);
    });

    test('desdeMapa(null) usa los valores por defecto', () {
      final p = PreferenciasPrivacidad.desdeMapa(null);

      expect(p.perfilPublico, isTrue);
      expect(p.mostrarNumero, isFalse);
    });

    test('ida y vuelta aMapa/desdeMapa conserva los valores', () {
      const original = PreferenciasPrivacidad(
        perfilPublico: false,
        permitirComentarios: false,
        mostrarNumero: true,
        mostrarFechaNacimiento: true,
        mostrarAmigos: false,
        mostrarVerificacion: false,
      );

      final copia = PreferenciasPrivacidad.desdeMapa(original.aMapa());

      expect(copia.aMapa(), original.aMapa());
      expect(copia.mostrarNumero, isTrue);
      expect(copia.mostrarFechaNacimiento, isTrue);
      expect(copia.mostrarAmigos, isFalse);
      expect(copia.mostrarVerificacion, isFalse);
    });

    test('copiarCon cambia solo el campo indicado', () {
      const original = PreferenciasPrivacidad();
      final nueva = original.copiarCon(mostrarNumero: true);

      expect(nueva.mostrarNumero, isTrue);
      expect(nueva.perfilPublico, original.perfilPublico);
      expect(nueva.mostrarAmigos, original.mostrarAmigos);
    });
  });

  group('PreferenciasNotificaciones', () {
    test('valores por defecto activados', () {
      const n = PreferenciasNotificaciones();

      expect(n.correosActivos, isTrue);
      expect(n.correoBienvenida, isTrue);
      expect(n.avisoNuevoIngreso, isTrue);
    });

    test('ida y vuelta aMapa/desdeMapa conserva los valores', () {
      const original = PreferenciasNotificaciones(
        correosActivos: false,
        correoBienvenida: false,
        avisoNuevoIngreso: true,
      );

      final copia = PreferenciasNotificaciones.desdeMapa(original.aMapa());

      expect(copia.aMapa(), original.aMapa());
      expect(copia.correosActivos, isFalse);
      expect(copia.correoBienvenida, isFalse);
      expect(copia.avisoNuevoIngreso, isTrue);
    });
  });

  group('AppAjustes (persistencia en el dispositivo)', () {
    test('guarda y recarga tema y escala de texto', () async {
      final ajustes = AppAjustes.instancia;

      await ajustes.cambiarTema(ThemeMode.dark);
      await ajustes.cambiarEscalaTexto(1.15);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ajustes_tema'), 'dark');
      expect(prefs.getDouble('ajustes_escala_texto'), 1.15);

      // Simula volver a abrir la app: se recargan los ajustes guardados.
      await ajustes.cargar();
      expect(ajustes.tema, ThemeMode.dark);
      expect(ajustes.escalaTexto, 1.15);
    });

    test('sin datos guardados usa tema del sistema y texto normal', () async {
      final ajustes = AppAjustes.instancia;

      await ajustes.cargar();

      expect(ajustes.tema, ThemeMode.system);
      expect(ajustes.escalaTexto, 1.0);
    });
  });

  group('ConfiguracionScreen', () {
    testWidgets('ofrece las tres opciones de tema y cuatro de tamaño', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ConfiguracionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tema del sistema'), findsOneWidget);
      expect(find.text('Tema claro'), findsOneWidget);
      expect(find.text('Tema oscuro'), findsOneWidget);

      expect(find.text('Pequeño'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Grande'), findsOneWidget);
      expect(find.text('Muy grande'), findsOneWidget);
    });

    testWidgets('tocar una opción actualiza el ajuste global', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ConfiguracionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tema oscuro'));
      await tester.pumpAndSettle();
      expect(AppAjustes.instancia.tema, ThemeMode.dark);

      await tester.tap(find.text('Grande'));
      await tester.pumpAndSettle();
      expect(AppAjustes.instancia.escalaTexto, 1.15);
    });
  });
}
