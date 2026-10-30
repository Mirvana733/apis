import 'package:flutter/material.dart';

import '../services/top_semana_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class BotonMeGusta extends StatefulWidget {
  const BotonMeGusta({
    super.key,
    required this.publicacionId,
    this.totalInicial = 0,
  });

  final String publicacionId;
  final int totalInicial;

  @override
  State<BotonMeGusta> createState() => _BotonMeGustaState();
}

class _BotonMeGustaState extends State<BotonMeGusta> {
  late int _total;
  bool? _meGusta;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _total = widget.totalInicial;
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final valor = await TopSemanaService.usuarioDioMeGusta(
      widget.publicacionId,
    );

    if (!mounted) return;

    setState(() {
      _meGusta = valor;
    });
  }

  Future<void> _alternar() async {
    if (_enviando || _meGusta == null) return;

    final anterior = _meGusta!;
    final nuevo = !anterior;

    setState(() {
      _enviando = true;
      _meGusta = nuevo;
      _total = nuevo ? _total + 1 : (_total > 0 ? _total - 1 : 0);
    });

    try {
      await TopSemanaService.alternarMeGusta(
        publicacionId: widget.publicacionId,
        meGusta: nuevo,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _meGusta = anterior;
        _total = nuevo ? (_total > 0 ? _total - 1 : 0) : _total + 1;
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activo = _meGusta == true;
    final colorActivo = Theme.of(context).brightness == Brightness.dark
        ? AppColors.estrella
        : AppColors.estrellaFuerte;
    final color = activo ? colorActivo : scheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _meGusta == null ? null : _alternar,
          icon: Icon(activo ? Icons.favorite : Icons.favorite_border),
          color: color,
          iconSize: 20,
          tooltip: activo ? 'Quitar Me gusta' : 'Me gusta',
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '$_total',
          style: AppTextStyles.caption.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}
