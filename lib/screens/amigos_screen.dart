import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/amistades_service.dart';
import '../services/perfil_publico_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/estrellas_reputacion.dart';
import '../widgets/fondo_lulilu.dart';
import 'perfil_amigo_screen.dart';

class AmigosScreen extends StatefulWidget {
  const AmigosScreen({super.key});

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen> {
  final TextEditingController _busqueda = TextEditingController();
  Timer? _temporizador;
  String _consulta = '';
  List<PerfilPublico> _resultados = const [];
  bool _buscando = false;
  String? _errorBusqueda;
  bool _procesando = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _temporizador?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  void _cambiarBusqueda(String valor) {
    _temporizador?.cancel();
    setState(() {
      _consulta = valor.trim();
      _errorBusqueda = null;

      if (_consulta.length < 2) {
        _resultados = const [];
        _buscando = false;
      }
    });

    if (_consulta.length < 2) return;

    _temporizador = Timer(const Duration(milliseconds: 350), () {
      _buscar();
    });
  }

  Future<void> _buscar() async {
    final consulta = _consulta;

    setState(() {
      _buscando = true;
      _errorBusqueda = null;
    });

    try {
      final resultados = await PerfilPublicoService.buscar(consulta);

      if (!mounted || consulta != _consulta) return;

      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    } catch (e) {
      debugPrint('Error al buscar personas: $e');

      if (!mounted || consulta != _consulta) return;

      setState(() {
        _buscando = false;
        _resultados = const [];
        _errorBusqueda = 'No se pudo realizar la búsqueda.';
      });
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      await accion();
    } on AmistadException catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (e) {
      debugPrint('Error al actualizar la amistad: $e');
      _mostrarMensaje('No se pudo completar la acción.');
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _abrirPerfil(String uid) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilAmigoScreen(uid: uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Amigos',
          style: AppTextStyles.headline.copyWith(
            fontSize: 25,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _busqueda,
                  onChanged: _cambiarBusqueda,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Buscar personas',
                    hintText: 'Escribe un nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_consulta.length >= 2)
                  _seccionBusqueda(scheme)
                else
                  StreamBuilder<List<Amistad>>(
                    stream: AmistadesService.streamMias(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return _aviso(
                          scheme,
                          icono: Icons.cloud_off_rounded,
                          texto: 'No se pudieron cargar tus amistades.',
                        );
                      }

                      final amistades = snapshot.data ?? const <Amistad>[];
                      final aceptadas = amistades
                          .where((amistad) => amistad.aceptada)
                          .toList();
                      final recibidas = amistades
                          .where(
                            (amistad) =>
                                amistad.pendiente &&
                                amistad.destinatario == _uid,
                          )
                          .toList();
                      final enviadas = amistades
                          .where(
                            (amistad) =>
                                amistad.pendiente &&
                                amistad.solicitante == _uid,
                          )
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (recibidas.isNotEmpty) ...[
                            _tituloSeccion(
                              scheme,
                              'Solicitudes recibidas',
                              Icons.mark_email_unread_outlined,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...recibidas.map(
                              (amistad) => _solicitudRecibida(scheme, amistad),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (enviadas.isNotEmpty) ...[
                            _tituloSeccion(
                              scheme,
                              'Solicitudes enviadas',
                              Icons.outbox_outlined,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...enviadas.map(
                              (amistad) => _solicitudEnviada(scheme, amistad),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _tituloSeccion(
                            scheme,
                            'Mis amigos',
                            Icons.people_alt_outlined,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (aceptadas.isEmpty)
                            _aviso(
                              scheme,
                              icono: Icons.group_outlined,
                              texto: 'Aún no tienes amigos. Busca a alguien por su nombre.',
                            )
                          else
                            ...aceptadas.map(
                              (amistad) => _amistadAceptada(scheme, amistad),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seccionBusqueda(ColorScheme scheme) {
    if (_buscando) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorBusqueda != null) {
      return _aviso(
        scheme,
        icono: Icons.cloud_off_rounded,
        texto: _errorBusqueda!,
      );
    }

    if (_resultados.isEmpty) {
      return _aviso(
        scheme,
        icono: Icons.search_off_outlined,
        texto: 'No encontramos personas con ese nombre.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tituloSeccion(scheme, 'Resultados', Icons.search),
        const SizedBox(height: AppSpacing.sm),
        ..._resultados.map((perfil) => _resultado(scheme, perfil)),
      ],
    );
  }

  Widget _tituloSeccion(ColorScheme scheme, String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 18, color: scheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          titulo,
          style: AppTextStyles.title.copyWith(
            fontSize: 17,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _resultado(ColorScheme scheme, PerfilPublico perfil) {
    return _tarjetaPersona(
      scheme,
      uid: perfil.uid,
      nombre: perfil.nombre,
      fotoPerfil: perfil.fotoPerfil,
      onTap: () => _abrirPerfil(perfil.uid),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _amistadAceptada(ColorScheme scheme, Amistad amistad) {
    final otroUid = amistad.otraUid(_uid);

    return StreamBuilder<PerfilPublico?>(
      stream: PerfilPublicoService.streamPerfil(otroUid),
      builder: (context, snapshot) {
        final perfil = snapshot.data;

        return _tarjetaPersona(
          scheme,
          uid: otroUid,
          nombre: perfil?.nombre ?? 'Amigo',
          fotoPerfil: perfil?.fotoPerfil,
          onTap: () => _abrirPerfil(otroUid),
          trailing: IconButton(
            tooltip: 'Eliminar amistad',
            onPressed: _procesando
                ? null
                : () async {
                    final confirmar = await _confirmarEliminar();

                    if (!confirmar) return;

                    await _ejecutar(() async {
                      await AmistadesService.eliminarAmistad(amistad.id);
                      _mostrarMensaje('Amistad eliminada.');
                    });
                  },
            icon: Icon(
              Icons.person_remove_outlined,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _solicitudRecibida(ColorScheme scheme, Amistad amistad) {
    final otroUid = amistad.solicitante;

    return StreamBuilder<PerfilPublico?>(
      stream: PerfilPublicoService.streamPerfil(otroUid),
      builder: (context, snapshot) {
        final perfil = snapshot.data;

        return _tarjetaPersona(
          scheme,
          uid: otroUid,
          nombre: perfil?.nombre ?? 'Usuario Lulilu',
          fotoPerfil: perfil?.fotoPerfil,
          onTap: () => _abrirPerfil(otroUid),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Rechazar',
                onPressed: _procesando
                    ? null
                    : () => _ejecutar(() async {
                        await AmistadesService.rechazarSolicitud(amistad.id);
                        _mostrarMensaje('Solicitud rechazada.');
                      }),
                icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
              ),
              IconButton(
                tooltip: 'Aceptar',
                onPressed: _procesando
                    ? null
                    : () => _ejecutar(() async {
                        await AmistadesService.aceptarSolicitud(amistad.id);
                        _mostrarMensaje('Ahora son amigos.');
                      }),
                icon: Icon(Icons.check, color: scheme.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _solicitudEnviada(ColorScheme scheme, Amistad amistad) {
    final otroUid = amistad.destinatario;

    return StreamBuilder<PerfilPublico?>(
      stream: PerfilPublicoService.streamPerfil(otroUid),
      builder: (context, snapshot) {
        final perfil = snapshot.data;

        return _tarjetaPersona(
          scheme,
          uid: otroUid,
          nombre: perfil?.nombre ?? 'Usuario Lulilu',
          fotoPerfil: perfil?.fotoPerfil,
          onTap: () => _abrirPerfil(otroUid),
          trailing: TextButton(
            onPressed: _procesando
                ? null
                : () => _ejecutar(() async {
                    await AmistadesService.cancelarSolicitud(amistad.id);
                    _mostrarMensaje('Solicitud cancelada.');
                  }),
            child: const Text('Cancelar'),
          ),
        );
      },
    );
  }

  Widget _tarjetaPersona(
    ColorScheme scheme, {
    required String uid,
    required String nombre,
    required String? fotoPerfil,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                AvatarUsuario(
                  fotoPerfil: fotoPerfil,
                  size: 44,
                  mostrarAnillo: false,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ReputacionEstrellasUsuario(uid: uid, size: 12),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aviso(
    ColorScheme scheme, {
    required IconData icono,
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icono, color: scheme.onSurfaceVariant, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarEliminar() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar amistad?'),
          content: const Text(
            'Podrán volver a agregarse. Las calificaciones anteriores se conservarán.',
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

    return resultado ?? false;
  }
}
