import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/amistades_service.dart';
import '../services/calificaciones_service.dart';
import '../services/perfil_publico_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/estrella_lulilu.dart';
import '../widgets/estrellas_reputacion.dart';
import '../widgets/fondo_lulilu.dart';

class PerfilAmigoScreen extends StatefulWidget {
  const PerfilAmigoScreen({super.key, required this.uid});

  final String uid;

  @override
  State<PerfilAmigoScreen> createState() => _PerfilAmigoScreenState();
}

class _PerfilAmigoScreenState extends State<PerfilAmigoScreen> {
  PerfilPublico? perfil;
  Amistad? amistad;
  int? miVoto;
  bool cargando = true;
  bool procesando = false;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      final perfilCargado = await PerfilPublicoService.obtener(widget.uid);
      final amistadCargada = await AmistadesService.obtenerAmistad(widget.uid);
      int? voto;

      try {
        voto = await CalificacionesService.obtenerMiVoto(widget.uid);
      } catch (_) {
        voto = null;
      }

      if (!mounted) return;

      setState(() {
        perfil = perfilCargado;
        amistad = amistadCargada;
        miVoto = voto;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar el perfil: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (procesando) return;

    setState(() => procesando = true);

    try {
      await accion();
      await cargar();
    } on AmistadException catch (e) {
      mostrarMensaje(e.mensaje);
    } on CalificacionException catch (e) {
      mostrarMensaje(e.mensaje);
    } catch (e) {
      debugPrint('Error al actualizar la amistad: $e');
      mostrarMensaje('No se pudo completar la acción.');
    } finally {
      if (mounted) {
        setState(() => procesando = false);
      }
    }
  }

  Future<void> enviarSolicitud() {
    return _ejecutar(() async {
      await AmistadesService.enviarSolicitud(widget.uid);
      mostrarMensaje('Solicitud enviada.');
    });
  }

  Future<void> aceptarSolicitud() {
    final actual = amistad;
    if (actual == null) return Future<void>.value();

    return _ejecutar(() async {
      await AmistadesService.aceptarSolicitud(actual.id);
      mostrarMensaje('Ahora son amigos.');
    });
  }

  Future<void> rechazarSolicitud() {
    final actual = amistad;
    if (actual == null) return Future<void>.value();

    return _ejecutar(() async {
      await AmistadesService.rechazarSolicitud(actual.id);
      mostrarMensaje('Solicitud rechazada.');
    });
  }

  Future<void> cancelarSolicitud() {
    final actual = amistad;
    if (actual == null) return Future<void>.value();

    return _ejecutar(() async {
      await AmistadesService.cancelarSolicitud(actual.id);
      mostrarMensaje('Solicitud cancelada.');
    });
  }

  Future<void> eliminarAmistad() async {
    final actual = amistad;
    if (actual == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar amistad?'),
          content: const Text(
            'Podrán volver a agregarse más adelante. Las calificaciones anteriores se conservarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _ejecutar(() async {
      await AmistadesService.eliminarAmistad(actual.id);
      mostrarMensaje('Amistad eliminada.');
    });
  }

  Future<void> calificar(int puntuacion) {
    return _ejecutar(() async {
      await CalificacionesService.calificar(
        calificadoUid: widget.uid,
        puntuacion: puntuacion,
      );
      miVoto = puntuacion;
      mostrarMensaje('Tu calificación fue guardada.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titulo = perfil?.nombre ?? 'Perfil';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          titulo,
          style: AppTextStyles.headline.copyWith(
            fontSize: 23,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          if (amistad?.aceptada ?? false)
            PopupMenuButton<String>(
              tooltip: 'Opciones',
              onSelected: (valor) {
                if (valor == 'eliminar') eliminarAmistad();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    leading: Icon(Icons.person_remove_outlined),
                    title: Text('Eliminar amistad'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FondoLulilu(
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: cargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _cabecera(scheme),
                        const SizedBox(height: AppSpacing.md),
                        _estadoAmistad(scheme),
                        if (amistad?.aceptada ?? false) ...[
                          const SizedBox(height: AppSpacing.md),
                          _tarjetaCalificacion(scheme),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _cabecera(ColorScheme scheme) {
    final actual = perfil;

    if (actual == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 38,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Este perfil no está disponible.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final oculto = !actual.perfilPublico && !(amistad?.aceptada ?? false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surfaceContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          AvatarUsuario(
            fotoPerfil: oculto ? null : actual.fotoPerfil,
            size: 86,
            mostrarAnillo: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            oculto ? 'Perfil privado' : actual.nombre,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline.copyWith(
              fontSize: 23,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!oculto) ...[
            StreamBuilder<Reputacion>(
              stream: CalificacionesService.streamReputacion(widget.uid),
              builder: (context, snapshot) {
                final reputacion = snapshot.data ?? const Reputacion.vacia();

                return EstrellasReputacion(
                  promedio: reputacion.promedio,
                  total: reputacion.total,
                  size: 22,
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Calificaciones de sus amigos',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (actual.verificado && actual.mostrarVerificacion) ...[
              const SizedBox(height: AppSpacing.sm),
              _insigniaVerificado(scheme),
            ],
          ] else ...[
            Text(
              'Agrega a esta persona como amistad para ver su información.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insigniaVerificado(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Cuenta verificada',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoAmistad(ColorScheme scheme) {
    final actual = amistad;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (actual == null) {
      if (perfil == null || perfil?.perfilPublico == false) {
        return const SizedBox.shrink();
      }

      return _accion(
        icono: Icons.person_add_alt_1_outlined,
        titulo: 'Agregar amigo',
        onTap: procesando ? null : enviarSolicitud,
      );
    }

    if (actual.pendiente) {
      final envieYo = actual.solicitante == uid;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _avisoEstado(
            scheme,
            icono: Icons.hourglass_top_rounded,
            texto: envieYo ? 'Solicitud enviada' : 'Solicitud recibida',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (envieYo)
            _accion(
              icono: Icons.close,
              titulo: 'Cancelar solicitud',
              onTap: procesando ? null : cancelarSolicitud,
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: procesando ? null : aceptarSolicitud,
                    child: const Text('Aceptar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: procesando ? null : rechazarSolicitud,
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    if (actual.aceptada) {
      return _avisoEstado(
        scheme,
        icono: Icons.people_alt_outlined,
        texto: 'Son amigos',
      );
    }

    return _accion(
      icono: Icons.person_add_alt_1_outlined,
      titulo: 'Volver a agregar',
      onTap: procesando ? null : enviarSolicitud,
    );
  }

  Widget _avisoEstado(
    ColorScheme scheme, {
    required IconData icono,
    required String texto,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icono, color: scheme.primary, size: 21),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.bodyStrong.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accion({
    required IconData icono,
    required String titulo,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icono, size: 18),
      label: Text(titulo),
    );
  }

  Widget _tarjetaCalificacion(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu calificación de hoy',
            style: AppTextStyles.title.copyWith(
              fontSize: 17,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Puedes cambiarla durante el día. Se guarda una vez por persona.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectorCalificacionEstrellas(
            seleccion: miVoto ?? 0,
            habilitado: !procesando,
            onChanged: calificar,
          ),
        ],
      ),
    );
  }
}

class SelectorCalificacionEstrellas extends StatelessWidget {
  const SelectorCalificacionEstrellas({
    super.key,
    required this.seleccion,
    required this.onChanged,
    this.habilitado = true,
  });

  final int seleccion;
  final ValueChanged<int> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (indice) {
        final valor = indice + 1;
        final activa = valor <= seleccion;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Semantics(
            button: true,
            label: '$valor estrellas',
            child: InkResponse(
              onTap: habilitado ? () => onChanged(valor) : null,
              radius: 26,
              child: EstrellaLulilu(
                size: 38,
                color: activa ? scheme.secondary : scheme.outlineVariant,
                colorBrillo: activa
                    ? scheme.onSecondaryContainer
                    : scheme.surfaceContainerHigh,
              ),
            ),
          ),
        );
      }),
    );
  }
}
