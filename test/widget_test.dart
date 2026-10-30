import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lulilu/main.dart';
import 'package:lulilu/theme/app_colors.dart';
import 'package:lulilu/theme/app_theme.dart';

void main() {
  double luminancia(Color c) {
    double canal(double v) {
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  }

  double contraste(Color a, Color b) {
    final la = luminancia(a);
    final lb = luminancia(b);
    final claro = math.max(la, lb);
    final oscuro = math.min(la, lb);
    return (claro + 0.05) / (oscuro + 0.05);
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearPlatformBrightnessTestValue();
  });

  testWidgets('la pantalla de inicio muestra la marca y los dos accesos', (
    tester,
  ) async {
    await tester.pumpWidget(const LuliluApp());

    expect(find.text('Lulilu'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('REGISTRARSE'), findsOneWidget);
  });

  testWidgets('el acceso lleva al formulario de inicio de sesión', (
    tester,
  ) async {
    await tester.pumpWidget(const LuliluApp());

    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  testWidgets('el registro lleva al formulario de creación de cuenta', (
    tester,
  ) async {
    await tester.pumpWidget(const LuliluApp());

    await tester.tap(find.text('REGISTRARSE'));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
  });

  testWidgets('el tema sigue al sistema: en modo oscuro se invierte el fondo', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    await tester.pumpWidget(const LuliluApp());
    await tester.pump();

    final contexto = tester.element(find.text('Lulilu'));
    final scheme = Theme.of(contexto).colorScheme;

    expect(scheme.brightness, Brightness.dark);
    expect(scheme.primary, AppColors.cristal);
    expect(scheme.surface, AppColors.noche);
  });

  test('la paleta de marca es la misma en claro y oscuro', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.cristal);
    expect(AppTheme.light.colorScheme.secondary, AppColors.estrella);
    expect(AppTheme.dark.colorScheme.primary, AppColors.cristal);
    expect(AppTheme.dark.colorScheme.surface, AppColors.noche);
  });

  test('el texto del acento estrella mantiene contraste AA sobre blanco', () {
    expect(
      contraste(AppColors.estrellaInk, AppColors.blanco),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('el texto de marca mantiene contraste AA en ambos modos', () {
    expect(
      contraste(AppColors.profundoFuerte, AppColors.cristal),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(AppColors.noche, AppColors.cristal),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('el cuerpo de texto sobre superficie es legible en ambos modos', () {
    expect(
      contraste(AppColors.profundo, AppColors.perla),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(AppColors.textoClaro, AppColors.superficieOscura),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('los pares del ColorScheme superan AA en modo claro', () {
    final c = AppTheme.light.colorScheme;

    expect(contraste(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
    expect(contraste(c.onSecondary, c.secondary), greaterThanOrEqualTo(4.5));
    expect(contraste(c.onSurface, c.surface), greaterThanOrEqualTo(4.5));
    expect(
      contraste(c.onSurfaceVariant, c.surfaceContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(c.onSecondaryContainer, c.secondaryContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(contraste(c.onError, c.error), greaterThanOrEqualTo(4.5));
  });

  test('los pares del ColorScheme superan AA en modo oscuro', () {
    final c = AppTheme.dark.colorScheme;

    expect(contraste(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
    expect(contraste(c.onSecondary, c.secondary), greaterThanOrEqualTo(4.5));
    expect(contraste(c.onSurface, c.surface), greaterThanOrEqualTo(4.5));
    expect(
      contraste(c.onSurfaceVariant, c.surfaceContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(c.onSecondaryContainer, c.secondaryContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(contraste(c.onError, c.error), greaterThanOrEqualTo(4.5));
  });

  test('el texto de los botones es legible en ambos modos', () {
    expect(
      contraste(AppColors.profundoFuerte, AppColors.cristal),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contraste(AppColors.noche, AppColors.cristal),
      greaterThanOrEqualTo(4.5),
    );
  });
}
