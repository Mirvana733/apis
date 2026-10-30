import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EstrellaLulilu extends StatelessWidget {
  const EstrellaLulilu({
    super.key,
    this.size = 28,
    this.color = AppColors.estrella,
    this.colorBrillo = AppColors.perla,
    this.conDestello = false,
  });

  final double size;
  final Color color;
  final Color colorBrillo;
  final bool conDestello;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PintorEstrella(
          color: color,
          colorBrillo: colorBrillo,
          conDestello: conDestello,
        ),
      ),
    );
  }
}

class DestelloLulilu extends StatelessWidget {
  const DestelloLulilu({
    super.key,
    this.size = 24,
    this.color = AppColors.estrella,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PintorDestello(color: color)),
    );
  }
}

class _PintorEstrella extends CustomPainter {
  const _PintorEstrella({
    required this.color,
    required this.colorBrillo,
    required this.conDestello,
  });

  final Color color;
  final Color colorBrillo;
  final bool conDestello;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final contorno = _rutaEstrella(centro, radio * 0.9, -math.pi / 2);

    canvas.drawPath(
      contorno,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorBrillo, Color.lerp(colorBrillo, color, 0.55)!, color],
        ).createShader(rect),
    );

    canvas.drawPath(
      contorno,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, radio * 0.055)
        ..strokeJoin = StrokeJoin.round
        ..color = colorBrillo.withValues(alpha: 0.8),
    );

    canvas.drawCircle(
      centro.translate(radio * 0.28, -radio * 0.3),
      math.max(0.7, radio * 0.075),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    if (conDestello) {
      canvas.drawPath(
        _rutaDestello(
          centro.translate(radio * 0.86, -radio * 0.68),
          radio * 0.36,
        ),
        Paint()..color = colorBrillo.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        centro.translate(-radio * 0.78, radio * 0.62),
        math.max(0.8, radio * 0.07),
        Paint()..color = color.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorEstrella oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.colorBrillo != colorBrillo ||
        oldDelegate.conDestello != conDestello;
  }
}

class _PintorDestello extends CustomPainter {
  const _PintorDestello({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.shortestSide / 2;

    canvas.drawPath(
      _rutaDestello(centro, radio * 0.9),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            color.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );

    canvas.drawCircle(
      centro,
      math.max(0.8, radio * 0.08),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _PintorDestello oldDelegate) {
    return oldDelegate.color != color;
  }
}

Path _rutaEstrella(Offset centro, double radio, double rotacion) {
  final ruta = Path();
  final radioInterior = radio * 0.42;

  for (var i = 0; i < 10; i++) {
    final actual = radio * (i.isEven ? 1 : radioInterior / radio);
    final angulo = rotacion + i * math.pi / 5;
    final punto = centro.translate(
      math.cos(angulo) * actual,
      math.sin(angulo) * actual,
    );

    if (i == 0) {
      ruta.moveTo(punto.dx, punto.dy);
    } else {
      ruta.lineTo(punto.dx, punto.dy);
    }
  }

  return ruta..close();
}

Path _rutaDestello(Offset centro, double largo) {
  final ancho = largo * 0.16;

  return Path()
    ..moveTo(centro.dx, centro.dy - largo)
    ..quadraticBezierTo(
      centro.dx + ancho,
      centro.dy - ancho,
      centro.dx + largo,
      centro.dy,
    )
    ..quadraticBezierTo(
      centro.dx + ancho,
      centro.dy + ancho,
      centro.dx,
      centro.dy + largo,
    )
    ..quadraticBezierTo(
      centro.dx - ancho,
      centro.dy + ancho,
      centro.dx - largo,
      centro.dy,
    )
    ..quadraticBezierTo(
      centro.dx - ancho,
      centro.dy - ancho,
      centro.dx,
      centro.dy - largo,
    )
    ..close();
}
