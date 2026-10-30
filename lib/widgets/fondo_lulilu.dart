import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FondoLulilu extends StatelessWidget {
  const FondoLulilu({
    super.key,
    this.child,
    this.intensidad = 1,
    this.mostrarEstrellas = true,
  });

  final Widget? child;
  final double intensidad;
  final bool mostrarEstrellas;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PintorFondoLulilu(
                  oscuro: oscuro,
                  intensidad: intensidad.clamp(0.0, 1.0),
                  mostrarEstrellas: mostrarEstrellas,
                ),
                isComplex: true,
                willChange: false,
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _PintorFondoLulilu extends CustomPainter {
  const _PintorFondoLulilu({
    required this.oscuro,
    required this.intensidad,
    required this.mostrarEstrellas,
  });

  final bool oscuro;
  final double intensidad;
  final bool mostrarEstrellas;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final rect = Offset.zero & size;
    final ancho = size.width;
    final alto = size.height;

    final fondo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: oscuro
            ? const [
                AppColors.nocheProfunda,
                Color(0xFF123246),
                Color(0xFF1B4A5F),
              ]
            : const [
                Color(0xFFE9F7FD),
                AppColors.cristalSuave,
                AppColors.perla,
              ],
        stops: const [0, 0.54, 1],
      ).createShader(rect);
    canvas.drawRect(rect, fondo);

    final luz = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.8),
        radius: 1.05,
        colors: [
          Colors.white.withValues(alpha: oscuro ? 0.10 : 0.55),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, luz);

    final calidez = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.9, 0.1),
        radius: 0.85,
        colors: [
          AppColors.estrella.withValues(alpha: oscuro ? 0.07 : 0.18),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, calidez);

    _pintarOndas(canvas, ancho, alto);
    _pintarReflejos(canvas, ancho, alto);

    if (mostrarEstrellas) {
      _pintarEstrellas(canvas, ancho, alto);
    }

    final velo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (oscuro ? AppColors.nocheProfunda : AppColors.perla).withValues(
            alpha: oscuro ? 0.20 : 0.28,
          ),
          Colors.transparent,
          (oscuro ? AppColors.noche : AppColors.perla).withValues(
            alpha: oscuro ? 0.16 : 0.18,
          ),
        ],
        stops: const [0, 0.42, 1],
      ).createShader(rect);
    canvas.drawRect(rect, velo);
  }

  void _pintarOndas(Canvas canvas, double ancho, double alto) {
    final olaLejana = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: oscuro ? 0.035 : 0.18);
    final olaCercana = Paint()
      ..style = PaintingStyle.fill
      ..color = (oscuro ? AppColors.cristal : AppColors.cristalClaro)
          .withValues(alpha: oscuro ? 0.05 : 0.24);

    final lejana = Path()
      ..moveTo(0, alto * 0.70)
      ..cubicTo(
        ancho * 0.22,
        alto * 0.66,
        ancho * 0.38,
        alto * 0.76,
        ancho * 0.55,
        alto * 0.71,
      )
      ..cubicTo(
        ancho * 0.72,
        alto * 0.66,
        ancho * 0.86,
        alto * 0.76,
        ancho,
        alto * 0.69,
      )
      ..lineTo(ancho, alto)
      ..lineTo(0, alto)
      ..close();
    canvas.drawPath(lejana, olaLejana);

    final cercana = Path()
      ..moveTo(0, alto * 0.80)
      ..cubicTo(
        ancho * 0.18,
        alto * 0.76,
        ancho * 0.34,
        alto * 0.85,
        ancho * 0.52,
        alto * 0.80,
      )
      ..cubicTo(
        ancho * 0.72,
        alto * 0.75,
        ancho * 0.88,
        alto * 0.84,
        ancho,
        alto * 0.79,
      )
      ..lineTo(ancho, alto)
      ..lineTo(0, alto)
      ..close();
    canvas.drawPath(cercana, olaCercana);
  }

  void _pintarReflejos(Canvas canvas, double ancho, double alto) {
    final reflejo = Paint()
      ..color = Colors.white.withValues(alpha: oscuro ? 0.045 : 0.34)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, ancho * 0.004);

    for (var i = 0; i < 5; i++) {
      final y = alto * (0.84 + i * 0.028);
      final inicio = ancho * (0.12 + i * 0.045);
      final largo = ancho * (0.16 + i * 0.055);
      canvas.drawLine(Offset(inicio, y), Offset(inicio + largo, y), reflejo);
    }
  }

  void _pintarEstrellas(Canvas canvas, double ancho, double alto) {
    final blanco = Colors.white.withValues(
      alpha: (oscuro ? 0.16 : 0.58) * intensidad,
    );
    final amarillo = AppColors.estrella.withValues(
      alpha: (oscuro ? 0.32 : 0.48) * intensidad,
    );
    final rellenoBlanco = Paint()..color = blanco;
    final rellenoAmarillo = Paint()..color = amarillo;
    final contorno = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, ancho * 0.0012)
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(
        alpha: (oscuro ? 0.10 : 0.36) * intensidad,
      );

    final principal = Rect.fromCircle(
      center: Offset(ancho * 0.87, alto * 0.12),
      radius: ancho * 0.1,
    );
    canvas.drawPath(
      _rutaEstrella(principal.center, principal.width / 2, -math.pi / 2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: (oscuro ? 0.18 : 0.7) * intensidad),
            amarillo,
          ],
        ).createShader(principal),
    );
    canvas.drawPath(
      _rutaEstrella(principal.center, principal.width / 2, -math.pi / 2),
      contorno,
    );
    canvas.drawCircle(
      Offset(ancho * 0.9, alto * 0.08),
      math.max(1.2, ancho * 0.006),
      Paint()..color = Colors.white.withValues(alpha: 0.75 * intensidad),
    );

    final estrellas = [
      (Offset(ancho * 0.09, alto * 0.42), ancho * 0.065, 0.24),
      (Offset(ancho * 0.78, alto * 0.74), ancho * 0.055, -0.36),
      (Offset(ancho * 0.45, alto * 0.19), ancho * 0.025, 0.42),
      (Offset(ancho * 0.93, alto * 0.47), ancho * 0.035, -0.12),
      (Offset(ancho * 0.21, alto * 0.87), ancho * 0.03, 0.36),
    ];

    for (var i = 0; i < estrellas.length; i++) {
      final estrella = estrellas[i];
      final ruta = _rutaEstrella(estrella.$1, estrella.$2, estrella.$3);
      final relleno = i.isEven ? rellenoBlanco : rellenoAmarillo;

      canvas.drawPath(ruta, relleno);
      canvas.drawPath(ruta, contorno);
    }

    final destellos = [
      (Offset(ancho * 0.61, alto * 0.27), ancho * 0.034, blanco),
      (Offset(ancho * 0.31, alto * 0.66), ancho * 0.024, amarillo),
      (Offset(ancho * 0.85, alto * 0.6), ancho * 0.018, blanco),
    ];

    for (final destello in destellos) {
      final ruta = _rutaDestello(destello.$1, destello.$2);
      canvas.drawPath(ruta, Paint()..color = destello.$3);
    }

    final puntos = [
      Offset(ancho * 0.18, alto * 0.18),
      Offset(ancho * 0.67, alto * 0.1),
      Offset(ancho * 0.38, alto * 0.78),
      Offset(ancho * 0.72, alto * 0.46),
      Offset(ancho * 0.12, alto * 0.6),
      Offset(ancho * 0.56, alto * 0.92),
    ];

    for (var i = 0; i < puntos.length; i++) {
      canvas.drawCircle(
        puntos[i],
        math.max(0.8, ancho * (i.isEven ? 0.0022 : 0.0032)),
        Paint()
          ..color = (i.isEven ? blanco : amarillo).withValues(
            alpha: (i.isEven ? blanco.a : amarillo.a) * 0.7,
          ),
      );
    }
  }

  Path _rutaEstrella(Offset centro, double radio, double rotacion) {
    final ruta = Path();
    final radioInterior = radio * 0.42;

    for (var i = 0; i < 10; i++) {
      final actual = i.isEven ? radio : radioInterior;
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

  @override
  bool shouldRepaint(covariant _PintorFondoLulilu oldDelegate) {
    return oldDelegate.oscuro != oscuro ||
        oldDelegate.intensidad != intensidad ||
        oldDelegate.mostrarEstrellas != mostrarEstrellas;
  }
}
