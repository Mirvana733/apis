import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Encabezado de sección + tarjeta contenedora para las pantallas de ajustes.
///
/// Unifica el estilo de Privacidad, Configuración y Notificaciones para no
/// repetir el mismo contenedor en cada archivo.
class SeccionAjustes extends StatelessWidget {
  const SeccionAjustes({super.key, required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xxs,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                titulo.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < hijos.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  hijos[i],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Fila con interruptor usada en Privacidad y Notificaciones.
class AjusteSwitch extends StatelessWidget {
  const AjusteSwitch({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.onChanged,
    this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String? descripcion;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _IconoAjuste(icono: icono, resaltado: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (descripcion != null)
                  Text(
                    descripcion!,
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Switch(value: valor, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Fila que navega a otra pantalla o ejecuta una acción.
class AjusteNavegacion extends StatelessWidget {
  const AjusteNavegacion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.onTap,
    this.descripcion,
    this.color,
  });

  final IconData icono;
  final String titulo;
  final String? descripcion;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      leading: _IconoAjuste(icono: icono, color: color),
      title: Text(
        titulo,
        style: AppTextStyles.bodyStrong.copyWith(
          color: color ?? scheme.onSurface,
        ),
      ),
      subtitle: descripcion == null
          ? null
          : Text(
              descripcion!,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
    );
  }
}

/// Opción seleccionable tipo radio, usada en Configuración.
class AjusteOpcion<T> extends StatelessWidget {
  const AjusteOpcion({
    super.key,
    required this.titulo,
    required this.valor,
    required this.grupo,
    required this.onChanged,
    this.descripcion,
  });

  final String titulo;
  final String? descripcion;
  final T valor;
  final T grupo;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seleccionado = valor == grupo;

    return ListTile(
      onTap: () => onChanged(valor),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      leading: _IconoAjuste(
        icono: seleccionado
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        resaltado: seleccionado,
      ),
      title: Text(
        titulo,
        style: AppTextStyles.bodyStrong.copyWith(color: scheme.onSurface),
      ),
      subtitle: descripcion == null
          ? null
          : Text(
              descripcion!,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _IconoAjuste extends StatelessWidget {
  const _IconoAjuste({required this.icono, this.color, this.resaltado = false});

  final IconData icono;
  final Color? color;
  final bool resaltado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colorIcono =
        color ??
        (resaltado ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
    final fondo = color != null
        ? color!.withValues(alpha: 0.12)
        : (resaltado ? scheme.primaryContainer : scheme.surfaceContainerHigh);

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icono, size: 20, color: colorIcono),
    );
  }
}
