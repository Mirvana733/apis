import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'estrella_lulilu.dart';

class EncabezadoMarca extends StatelessWidget {
  const EncabezadoMarca({
    super.key,
    this.titulo = 'Lulilu',
    required this.mensaje,
    this.compacto = false,
    this.alineacion = CrossAxisAlignment.center,
    this.colorTitulo,
    this.colorMensaje,
    this.colorAcento,
    this.mostrarDetalle = true,
  });

  final String titulo;
  final String mensaje;
  final bool compacto;
  final CrossAxisAlignment alineacion;
  final Color? colorTitulo;
  final Color? colorMensaje;
  final Color? colorAcento;
  final bool mostrarDetalle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final acento = colorAcento ?? scheme.secondary;
    final tituloColor = colorTitulo ?? scheme.onSurface;
    final mensajeColor = colorMensaje ?? scheme.onSurfaceVariant;
    final textAlign = alineacion == CrossAxisAlignment.start
        ? TextAlign.start
        : TextAlign.center;

    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alineacion,
        children: [
          if (mostrarDetalle) ...[
            EstrellaLulilu(
              size: compacto ? 24 : 32,
              color: acento,
              colorBrillo: AppColors.perla,
              conDestello: !compacto,
            ),
            SizedBox(height: compacto ? 8 : 12),
          ],
          Text(
            titulo,
            textAlign: textAlign,
            style: (compacto ? AppTextStyles.marcaSuave : AppTextStyles.marca)
                .copyWith(color: tituloColor),
          ),
          SizedBox(height: compacto ? 6 : 9),
          if (mostrarDetalle) ...[
            _LineaAcento(color: acento, ancho: compacto ? 40 : 56),
            SizedBox(height: compacto ? 9 : 12),
          ],
          Text(
            mensaje,
            textAlign: textAlign,
            style: (compacto ? AppTextStyles.caption : AppTextStyles.body)
                .copyWith(color: mensajeColor),
          ),
        ],
      ),
    );
  }
}

class _LineaAcento extends StatelessWidget {
  const _LineaAcento({required this.color, required this.ancho});

  final Color color;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
