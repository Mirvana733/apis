import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Avatar circular del usuario.
///
/// Muestra la foto guardada en Storage (`fotoPerfil`) y cae de vuelta al icono
/// de persona si no hay foto, si sigue cargando o si falla la descarga.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.fotoPerfil,
    required this.size,
    this.colorFondo,
    this.colorIcono,
    this.tamanoIcono,
    this.mostrarAnillo = false,
    this.colorAnillo,
    this.grosorAnillo = 2.5,
  });

  final String? fotoPerfil;
  final double size;
  final Color? colorFondo;
  final Color? colorIcono;
  final double? tamanoIcono;
  final bool mostrarAnillo;
  final Color? colorAnillo;
  final double grosorAnillo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fondo = colorFondo ?? scheme.primaryContainer;
    final icono = colorIcono ?? scheme.onPrimaryContainer;
    final String? ruta = (fotoPerfil == null || fotoPerfil!.isEmpty)
        ? null
        : fotoPerfil;

    if (!mostrarAnillo) {
      return SizedBox(
        width: size,
        height: size,
        child: _contenido(ruta, fondo, icono, size),
      );
    }

    final ladoCalculado = size - grosorAnillo * 2 - 4;
    final ladoInterior = ladoCalculado < 0 ? 0.0 : ladoCalculado;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(grosorAnillo),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorAnillo,
        gradient: colorAnillo == null
            ? LinearGradient(colors: [scheme.primary, scheme.secondary])
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainer,
        ),
        child: _contenido(ruta, fondo, icono, ladoInterior),
      ),
    );
  }

  Widget _contenido(String? ruta, Color fondo, Color icono, double lado) {
    if (ruta == null) {
      return _placeholder(fondo, icono, lado);
    }

    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(ruta).getDownloadURL(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _placeholder(fondo, icono, lado);
        }

        return ClipOval(
          child: Image.network(
            snapshot.data!,
            width: lado,
            height: lado,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                _placeholder(fondo, icono, lado),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _placeholder(fondo, icono, lado);
            },
          ),
        );
      },
    );
  }

  Widget _placeholder(Color fondo, Color icono, double lado) {
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Icon(Icons.person, color: icono, size: tamanoIcono ?? lado * 0.55),
    );
  }
}
