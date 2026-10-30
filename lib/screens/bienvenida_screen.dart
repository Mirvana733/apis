import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/encabezado_marca.dart';
import '../widgets/estrella_lulilu.dart';
import '../widgets/fondo_lulilu.dart';
import 'inicio_shell.dart';

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

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const InicioShell()));
    });
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FondoLulilu(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: controlador,
                      builder: (context, child) {
                        final escala =
                            1 + math.sin(controlador.value * math.pi) * 0.045;

                        return Transform.scale(scale: escala, child: child);
                      },
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.surface.withValues(alpha: 0.8),
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: EstrellaLulilu(
                            size: 50,
                            color: scheme.secondary,
                            conDestello: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EncabezadoMarca(
                      mensaje: 'Conecta, comparte y comunica con respeto.',
                      colorTitulo: scheme.onSurface,
                      colorMensaje: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Tu espacio para compartir y conectar.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Preparando tu espacio',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
