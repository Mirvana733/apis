import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pantalla_principal.dart';

class BienvenidaScreen extends StatefulWidget {
  const BienvenidaScreen({super.key});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controlador;

  @override
  void initState() {
    super.initState();

    controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    Future.delayed(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PantallaPrincipal(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.welcomeBackground1,
              AppColors.welcomeBackground2,
              AppColors.welcomeBackground3,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: controlador,
          builder: (context, child) {
            final movimiento =
                math.sin(
                  controlador.value * math.pi * 2,
                ) *
                35;

            return Stack(
              children: [
                Positioned(
                  left: 35,
                  top: 130 + movimiento,
                  child: _estrellita(
                    tamano: 75,
                    rotacion: controlador.value * 0.15,
                  ),
                ),
                Positioned(
                  right: 30,
                  top: 220 - movimiento,
                  child: _estrellita(
                    tamano: 45,
                    rotacion: -controlador.value * 0.20,
                  ),
                ),
                Positioned(
                  left: 70,
                  bottom: 180 - movimiento,
                  child: _estrellita(
                    tamano: 40,
                    rotacion: controlador.value * 0.18,
                  ),
                ),
                Positioned(
                  right: 70,
                  bottom: 120 + movimiento,
                  child: _estrellita(
                    tamano: 65,
                    rotacion: -controlador.value * 0.15,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _estrellita(
                        tamano: 150,
                        rotacion: controlador.value * 0.10,
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        '¡Bienvenido a Lulilu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.welcomeTitle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu espacio para compartir y conectar 💗',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _estrellita({
    required double tamano,
    required double rotacion,
  }) {
    return Transform.rotate(
      angle: rotacion,
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: CustomPaint(
          painter: EstrellaPainter(),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: tamano * 0.11,
                  height: tamano * 0.15,
                  decoration: const BoxDecoration(
                    color: AppColors.starFace,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: tamano * 0.09),
                Container(
                  width: tamano * 0.11,
                  height: tamano * 0.15,
                  decoration: const BoxDecoration(
                    color: AppColors.starFace,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EstrellaPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final centro = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radioExterno = size.width / 2;
    final radioInterno = radioExterno * 0.45;

    final path = Path();

    for (int i = 0; i < 10; i++) {
      final angulo =
          -math.pi / 2 +
          i * math.pi / 5;

      final radio = i.isEven
          ? radioExterno
          : radioInterno;

      final punto = Offset(
        centro.dx + math.cos(angulo) * radio,
        centro.dy + math.sin(angulo) * radio,
      );

      if (i == 0) {
        path.moveTo(
          punto.dx,
          punto.dy,
        );
      } else {
        path.lineTo(
          punto.dx,
          punto.dy,
        );
      }
    }

    path.close();

    final pintura = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.starLight,
          AppColors.starCyan,
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawPath(
      path,
      pintura,
    );
  }

  @override
  bool shouldRepaint(
    CustomPainter oldDelegate,
  ) {
    return false;
  }
}