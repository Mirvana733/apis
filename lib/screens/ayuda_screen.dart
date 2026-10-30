import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/fondo_lulilu.dart';

class _Pregunta {
  const _Pregunta(this.categoria, this.pregunta, this.respuesta);

  final String categoria;
  final String pregunta;
  final String respuesta;
}

const List<_Pregunta> _preguntas = [
  // Cuenta y registro
  _Pregunta(
    'Cuenta y registro',
    '¿Cómo creo mi cuenta en Lulilu?',
    'Toca REGISTRARSE en la pantalla de inicio, completa tus datos (nombre, apellidos, fecha de nacimiento, correo y número), agrega una foto de tu CI y realiza la verificación con la cámara frontal. Al terminar recibirás un correo de bienvenida.',
  ),
  _Pregunta(
    'Cuenta y registro',
    '¿Por qué debo verificar mi identidad al registrarme?',
    'La verificación con tu CI y una selfie ayuda a que las cuentas sean reales y reduce perfiles falsos. Al registrarte, la app compara tu rostro con la foto de tu documento.',
  ),
  _Pregunta(
    'Cuenta y registro',
    '¿Cómo cambio mi contraseña?',
    'Abre Mi perfil, entra al menú de opciones y elige "Cambiar contraseña". Por seguridad te pediremos tu contraseña actual antes de guardar la nueva.',
  ),
  _Pregunta(
    'Cuenta y registro',
    '¿Cómo elimino mi cuenta?',
    'En Mi perfil, abre el menú de opciones y elige "Eliminar mi cuenta". Se borrarán tu cuenta, publicaciones y comentarios de forma permanente. Esta acción no se puede deshacer.',
  ),

  // Publicaciones y contenido
  _Pregunta(
    'Publicaciones y contenido',
    '¿Qué tipo de contenido puedo publicar?',
    'Puedes compartir publicaciones de texto e imágenes desde el botón "Crear" de la pantalla principal. Todo el contenido pasa por un filtro de moderación antes de publicarse.',
  ),
  _Pregunta(
    'Publicaciones y contenido',
    '¿Por qué mi publicación no aparece?',
    'Tu contenido puede estar en revisión, o haber sido bloqueado o rechazado por la moderación automática si contiene lenguaje ofensivo, contenido sexual, violencia o spam. Recibirás un mensaje con el resultado.',
  ),
  _Pregunta(
    'Publicaciones y contenido',
    '¿Qué significa que un contenido esté "en revisión"?',
    'Algunas publicaciones con imágenes o videos requieren un análisis más lento. Mientras se procesan, no se muestran en el feed. En cuanto terminen, se publican o se rechazan automáticamente.',
  ),
  _Pregunta(
    'Publicaciones y contenido',
    '¿Puedo comentar las publicaciones de otros?',
    'Sí. Toca el ícono de comentarios en una publicación para abrir la lista y escribir el tuyo. Los comentarios también pasan por moderación antes de publicarse.',
  ),

  // Verificación de identidad
  _Pregunta(
    'Verificación de identidad',
    '¿Cómo verifico mi identidad después de registrarme?',
    'En Mi perfil, abre el menú de opciones y elige "Verificar mi identidad". Sube una foto de tu CI y toma una selfie con la cámara frontal. Si coinciden, tu cuenta aparecerá como verificada.',
  ),
  _Pregunta(
    'Verificación de identidad',
    '¿Por qué no pudo verificarse mi identidad?',
    'Asegúrate de que la foto de tu CI sea legible, que el número de documento coincida con el que ingresaste y que la selfie muestre tu rostro con buena luz. Si falla, puedes intentarlo de nuevo.',
  ),
  _Pregunta(
    'Verificación de identidad',
    '¿Para qué sirve el distintivo de verificado?',
    'El check azul indica que tu identidad fue confirmada y da mayor confianza a otros usuarios. Puedes ocultarlo desde Privacidad si lo prefieres.',
  ),

  // Privacidad y seguridad
  _Pregunta(
    'Privacidad y seguridad',
    '¿Cómo controlo quién ve mi información?',
    'Abre Privacidad en el menú de Mi perfil. Desde ahí puedes decidir si tu perfil es público y si se muestran tu número, tu fecha de nacimiento, tu lista de amigos y tu distintivo de verificación.',
  ),
  _Pregunta(
    'Privacidad y seguridad',
    '¿Cómo edito los datos de mi perfil?',
    'En el menú de Mi perfil elige "Editar perfil" para cambiar tu nombre, apellidos, número de celular y fecha de nacimiento. El correo de acceso no se cambia desde ahí.',
  ),
  _Pregunta(
    'Privacidad y seguridad',
    '¿Mis datos están seguros?',
    'Tus datos se guardan con la infraestructura de Firebase y solo tú puedes leer y editar tu documento de perfil. Consulta la "Política de información" para más detalle.',
  ),
  _Pregunta(
    'Privacidad y seguridad',
    '¿Cómo cambio mi foto de perfil?',
    'En el menú de Mi perfil elige "Cambiar foto". Puedes tomarte una nueva o elegirla de tu galería, y se actualizará en tu perfil y publicaciones.',
  ),

  // Moderación
  _Pregunta(
    'Moderación',
    '¿Qué contenido no está permitido?',
    'No se permite contenido ofensivo, sexual, violento, de odio, amenazas, acoso, spam o peligroso. La moderación automática revisa el texto, las imágenes, los videos y el audio.',
  ),
  _Pregunta(
    'Moderación',
    '¿La moderación es automática?',
    'Sí. La app analiza el contenido con herramientas automáticas y decide si se aprueba, se bloquea o se rechaza. En algunos casos el material puede quedar en revisión.',
  ),
  _Pregunta(
    'Moderación',
    '¿Por qué se bloqueó mi comentario?',
    'Un comentario se bloquea cuando el análisis detecta lenguaje ofensivo, acoso, amenazas o contenido inapropiado. Puedes intentar escribirlo de otra forma respetuosa.',
  ),

  // Notificaciones
  _Pregunta(
    'Notificaciones',
    '¿Qué avisos envía Lulilu?',
    'Lulilu envía correos de bienvenida al crear tu cuenta y avisos de inicio de sesión cuando se accede desde un dispositivo nuevo.',
  ),
  _Pregunta(
    'Notificaciones',
    '¿Cómo activo o desactivo los correos?',
    'Abre Notificaciones en el menú de Mi perfil. Puedes apagar todos los correos o elegir qué tipos de aviso quieres recibir.',
  ),
];

class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> {
  final buscarController = TextEditingController();
  String consulta = '';

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  String _normalizar(String valor) {
    const conAcentos = 'áéíóúüñ';
    const sinAcentos = 'aeiouun';

    final buffer = StringBuffer();

    for (final letra in valor.toLowerCase().split('')) {
      final indice = conAcentos.indexOf(letra);
      buffer.write(indice >= 0 ? sinAcentos[indice] : letra);
    }

    return buffer.toString();
  }

  List<_Pregunta> get _filtradas {
    final texto = _normalizar(consulta.trim());
    if (texto.isEmpty) return _preguntas;

    return _preguntas
        .where(
          (p) =>
              _normalizar(p.pregunta).contains(texto) ||
              _normalizar(p.respuesta).contains(texto) ||
              _normalizar(p.categoria).contains(texto),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resultados = _filtradas;

    final Map<String, List<_Pregunta>> porCategoria = {};
    for (final pregunta in resultados) {
      porCategoria.putIfAbsent(pregunta.categoria, () => []).add(pregunta);
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Ayuda',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: buscarController,
                  onChanged: (valor) => setState(() => consulta = valor),
                  decoration: InputDecoration(
                    hintText: 'Buscar en las preguntas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: consulta.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              buscarController.clear();
                              setState(() => consulta = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: resultados.isEmpty
                    ? _sinResultados(scheme)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        children: [
                          for (final entrada in porCategoria.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xxs,
                                bottom: AppSpacing.xs,
                              ),
                              child: Text(
                                entrada.key.toUpperCase(),
                                style: AppTextStyles.overline.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            _tarjetaCategoria(entrada.value, scheme),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaCategoria(List<_Pregunta> items, ColorScheme scheme) {
    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              iconColor: scheme.primary,
              collapsedIconColor: scheme.onSurfaceVariant,
              title: Text(
                items[i].pregunta,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    items[i].respuesta,
                    style: AppTextStyles.body.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sinResultados(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No encontramos preguntas para "$consulta".',
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
}
