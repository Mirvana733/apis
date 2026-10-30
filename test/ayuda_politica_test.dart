import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulilu/screens/ayuda_screen.dart';
import 'package:lulilu/screens/politica_informacion_screen.dart';

void main() {
  group('AyudaScreen', () {
    testWidgets('muestra la marca y las preguntas frecuentes', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AyudaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ayuda'), findsOneWidget);
      expect(find.text('¿Cómo cambio mi contraseña?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filtra las preguntas por texto', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AyudaScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'elimino mi cuenta');
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo elimino mi cuenta?'), findsOneWidget);
      expect(find.text('¿Cómo cambio mi contraseña?'), findsNothing);
    });

    testWidgets('ignora acentos al buscar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AyudaScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'publicacion');
      await tester.pumpAndSettle();

      expect(
        find.text('¿Qué tipo de contenido puedo publicar?'),
        findsOneWidget,
      );
    });

    testWidgets('muestra un aviso cuando no hay resultados', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AyudaScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzznoexiste');
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos preguntas'), findsOneWidget);
    });

    testWidgets('al tocar una pregunta despliega la respuesta', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AyudaScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('¿Cómo cambio mi contraseña?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cambiar contraseña'), findsWidgets);
    });
  });

  group('PoliticaInformacionScreen', () {
    testWidgets('muestra el título y las primeras secciones', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PoliticaInformacionScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Política de información'), findsOneWidget);
      expect(find.text('Información que recopilamos'), findsOneWidget);
      expect(
        find.textContaining('Cómo usamos, almacenamos y protegemos'),
        findsOneWidget,
      );
    });
  });
}
