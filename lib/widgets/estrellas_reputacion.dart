import 'package:flutter/material.dart';

import '../services/calificaciones_service.dart';
import '../theme/app_colors.dart';
import 'estrella_lulilu.dart';

class EstrellasReputacion extends StatelessWidget {
  const EstrellasReputacion({
    super.key,
    required this.promedio,
    required this.total,
    this.size = 16,
  });

  final double promedio;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valor = total == 0 ? 5.0 : promedio.clamp(0, 5).toDouble();

    return Semantics(
      label: total == 0
          ? 'Sin calificaciones'
          : '${valor.toStringAsFixed(1)} de 5 estrellas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (indice) {
          final fraccion = (valor - indice).clamp(0, 1).toDouble();

          return Padding(
            padding: EdgeInsets.only(right: indice == 4 ? 0 : size * 0.08),
            child: _estrella(
              fraccion: fraccion,
              colorLlena: scheme.secondary,
              colorVacia: scheme.outlineVariant,
              colorBrilloVacia: scheme.surfaceContainerHigh,
            ),
          );
        }),
      ),
    );
  }

  Widget _estrella({
    required double fraccion,
    required Color colorLlena,
    required Color colorVacia,
    required Color colorBrilloVacia,
  }) {
    final vacia = EstrellaLulilu(
      size: size,
      color: colorVacia,
      colorBrillo: colorBrilloVacia,
    );

    if (fraccion <= 0) return vacia;

    final llena = EstrellaLulilu(
      size: size,
      color: colorLlena,
      colorBrillo: AppColors.perla,
    );

    if (fraccion >= 1) return llena;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          vacia,
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: fraccion,
              child: llena,
            ),
          ),
        ],
      ),
    );
  }
}

class ReputacionEstrellasUsuario extends StatelessWidget {
  const ReputacionEstrellasUsuario({
    super.key,
    required this.uid,
    this.size = 14,
  });

  final String uid;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<Reputacion>(
      stream: CalificacionesService.streamReputacion(uid),
      builder: (context, snapshot) {
        final reputacion = snapshot.data ?? const Reputacion.vacia();

        return EstrellasReputacion(
          promedio: reputacion.promedio,
          total: reputacion.total,
          size: size,
        );
      },
    );
  }
}
