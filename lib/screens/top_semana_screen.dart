import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../services/top_semana_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/fondo_lulilu.dart';

class TopSemanaScreen extends StatefulWidget {
  const TopSemanaScreen({super.key});

  @override
  State<TopSemanaScreen> createState() => _TopSemanaScreenState();
}

class _TopSemanaScreenState extends State<TopSemanaScreen> {
  late PeriodoSemana periodoActual;
  late PeriodoSemana periodo;
  late Stream<ResultadoTopSemana> _oficial;
  late Stream<ResultadoTopSemana> _enVivo;

  @override
  void initState() {
    super.initState();
    periodoActual = TopSemanaService.semanaActual();
    periodo = TopSemanaService.periodoPublicado();
    _oficial = TopSemanaService.streamTopSemana(periodo);
    _enVivo = TopSemanaService.streamEnVivo(periodoActual);
  }

  bool get _mostrarEnVivo =>
      !periodoActual.finalizado &&
      periodo.id == TopSemanaService.periodoPublicado().id;

  void _seleccionarPeriodo(PeriodoSemana nuevo) {
    setState(() {
      periodo = nuevo;
      _oficial = TopSemanaService.streamTopSemana(nuevo);
    });
  }

  Future<void> _abrirHistorial() async {
    List<ResultadoTopSemana> semanas = const [];

    try {
      semanas = await TopSemanaService.historial();
    } catch (_) {
      semanas = const [];
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semanas anteriores',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 22,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Consulta los resultados que ya cerraron.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (semanas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'Todavía no hay semanas guardadas.',
                    style: AppTextStyles.body.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: semanas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final semana = semanas[index];
                      final actual = semana.periodo.id == periodo.id;

                      return Material(
                        color: Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: actual
                                ? scheme.primaryContainer
                                : scheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: actual
                                  ? scheme.primary.withValues(alpha: 0.5)
                                  : scheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            leading: Icon(
                              actual
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.history_rounded,
                              color: actual
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                            title: Text(
                              semana.periodo.etiqueta,
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${semana.topMeGusta.length} destacadas · '
                              '${semana.topComentarios.length} más comentadas',
                              style: AppTextStyles.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _seleccionarPeriodo(semana.periodo);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          title: Text(
            'Top de la semana',
            style: AppTextStyles.headline.copyWith(
              fontSize: 24,
              color: scheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _abrirHistorial,
              icon: const Icon(Icons.history_rounded),
              color: scheme.onSurface,
              tooltip: 'Semanas anteriores',
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          bottom: TabBar(
            indicatorColor: scheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: scheme.onSurface,
            unselectedLabelColor: scheme.onSurfaceVariant,
            dividerColor: scheme.outlineVariant,
            tabs: const [
              Tab(text: 'Top Me gusta', icon: Icon(Icons.favorite_rounded)),
              Tab(
                text: 'Top comentarios',
                icon: Icon(Icons.mode_comment_rounded),
              ),
            ],
          ),
        ),
        body: FondoLulilu(
          child: StreamBuilder<ResultadoTopSemana>(
            stream: _oficial,
            builder: (context, snapshot) {
              return _cuerpo(snapshot);
            },
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(AsyncSnapshot<ResultadoTopSemana> snapshot) {
    final scheme = Theme.of(context).colorScheme;

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No se pudo cargar el Top de la semana.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final datos = snapshot.data!;

    return Column(
      children: [
        _encabezado(datos),
        Expanded(
          child: StreamBuilder<ResultadoTopSemana>(
            stream: _mostrarEnVivo ? _enVivo : null,
            builder: (context, snapshotVivo) {
              return TabBarView(
                children: [
                  _contenidoCategoria(datos, snapshotVivo, true),
                  _contenidoCategoria(datos, snapshotVivo, false),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _encabezado(ResultadoTopSemana valor) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: scheme.onSurface,
                  size: 19,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  valor.periodo.etiqueta,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.emoji_events_rounded,
                color: scheme.secondary,
                size: 25,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            valor.generado
                ? (periodoActual.finalizado
                      ? 'Resultados oficiales de la semana que acaba de cerrar.'
                      : 'Ganadores oficiales de la última semana cerrada.')
                : 'Resultados provisionales: el servidor todavía no publicó '
                      'el Top de esta semana.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoCategoria(
    ResultadoTopSemana oficial,
    AsyncSnapshot<ResultadoTopSemana> snapshotVivo,
    bool esMeGusta,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final listaOficial = esMeGusta
        ? oficial.topMeGusta
        : oficial.topComentarios;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _tituloSeccion(
          'Ganadores oficiales de la semana',
          Icons.emoji_events_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (listaOficial.isEmpty)
          _sinResultados(
            scheme,
            esMeGusta
                ? 'Todavía no hay ganadores guardados de esta semana.'
                : 'Todavía no hay comentarios destacados de esta semana.',
          )
        else
          ...List.generate(
            listaOficial.length,
            (indice) => _tarjeta(listaOficial[indice], indice, esMeGusta),
          ),
        if (_mostrarEnVivo) ...[
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          _tituloSeccion(
            'Conteo en vivo · semana en curso',
            Icons.bolt_rounded,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Aún no es el resultado final: se publica el domingo a las 00:00.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _enVivoLista(snapshotVivo, esMeGusta),
        ],
      ],
    );
  }

  Widget _sinResultados(ColorScheme scheme, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        texto,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _enVivoLista(
    AsyncSnapshot<ResultadoTopSemana> snapshot,
    bool esMeGusta,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final datos = snapshot.data;
    final lista = datos == null
        ? const <PublicacionTop>[]
        : (esMeGusta ? datos.topMeGusta : datos.topComentarios);

    if (lista.isEmpty) {
      return _sinResultados(
        scheme,
        esMeGusta
            ? 'Todavía no hay Me gusta esta semana.'
            : 'Todavía no hay comentarios esta semana.',
      );
    }

    return Column(
      children: List.generate(
        lista.length,
        (indice) => _tarjeta(lista[indice], indice, esMeGusta),
      ),
    );
  }

  Widget _tituloSeccion(String texto, IconData icono) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icono, size: 18, color: scheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            texto,
            style: AppTextStyles.title.copyWith(
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(PublicacionTop publicacion, int indice, bool esMeGusta) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _medalla(indice + 1),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publicacion.nombreAutor,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  if (publicacion.texto.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      publicacion.texto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        esMeGusta
                            ? Icons.favorite_rounded
                            : Icons.mode_comment_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        esMeGusta
                            ? '${publicacion.meGusta} Me gusta'
                            : '${publicacion.comentarios} comentarios',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _miniatura(publicacion.mediaUrl),
          ],
        ),
      ),
    );
  }

  Widget _medalla(int posicion) {
    final color = switch (posicion) {
      1 => const Color(0xFFE6B325),
      2 => const Color(0xFFB7C2CA),
      3 => const Color(0xFFC98555),
      _ => Theme.of(context).colorScheme.primaryContainer,
    };

    final colorTexto = posicion <= 3
        ? const Color(0xFF2A2418)
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$posicion',
        style: AppTextStyles.bodyStrong.copyWith(
          color: colorTexto,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _miniatura(String mediaUrl) {
    final scheme = Theme.of(context).colorScheme;

    if (mediaUrl.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 52,
        height: 52,
        child: FutureBuilder<String>(
          future: FirebaseStorage.instance.ref(mediaUrl).getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.network(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
              );
            }

            if (snapshot.hasError) {
              return Icon(Icons.image_outlined, color: scheme.onSurfaceVariant);
            }

            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
