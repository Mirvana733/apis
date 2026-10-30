import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/fondo_lulilu.dart';

class _Seccion {
  const _Seccion(this.titulo, this.parrafos);

  final String titulo;
  final List<String> parrafos;
}

const List<_Seccion> _secciones = [
  _Seccion('Información que recopilamos', [
    'Datos de la cuenta: nombre, apellidos, fecha de nacimiento, correo electrónico y número de celular que proporcionas al registrarte.',
    'Datos de verificación: la foto de tu cédula de identidad y una selfie, que se usan únicamente para comprobar tu identidad. La foto del documento se elimina después de la verificación.',
    'Contenido: las publicaciones, imágenes y comentarios que creas dentro de la app.',
    'Datos técnicos: información básica del dispositivo y de los inicios de sesión, para poder avisarte de accesos desde dispositivos nuevos.',
  ]),
  _Seccion('Cómo usamos tu información', [
    'Para crear y administrar tu cuenta y permitirte iniciar sesión.',
    'Para mostrar tu perfil, tus publicaciones y tus comentarios dentro de la app.',
    'Para verificar tu identidad y otorgar el distintivo de cuenta verificada.',
    'Para moderar el contenido y mantener un entorno seguro y respetuoso.',
    'Para enviarte avisos por correo, como la bienvenida o el aviso de un nuevo inicio de sesión, según tus preferencias.',
  ]),
  _Seccion('Almacenamiento y seguridad', [
    'Tus datos se almacenan de forma segura en los servicios de Firebase (Google): autenticación, base de datos, almacenamiento de archivos y funciones.',
    'El acceso a tu perfil está protegido: solo tú puedes leer y editar tu documento de usuario. Las imágenes de tu perfil y tus publicaciones requieren una sesión iniciada para verse.',
    'Aplicamos reglas de seguridad en el servidor para que nadie pueda modificar la información de otra persona.',
  ]),
  _Seccion('Servicios de terceros', [
    'Firebase (Google): autenticación de usuarios, base de datos, almacenamiento de archivos y ejecución de funciones.',
    'Servicios de correo: para enviar los mensajes de bienvenida y de aviso de inicio de sesión.',
    'Servicios de análisis automático de contenido: para revisar el texto, las imágenes, los videos y el audio y detectar material inapropiado.',
    'La verificación de identidad puede apoyarse en herramientas de reconocimiento facial y de lectura de documentos.',
  ]),
  _Seccion('Cuándo compartimos información', [
    'No vendemos ni alquilamos tus datos personales.',
    'Solo compartimos información con los proveedores que hacen posible el funcionamiento de la app (por ejemplo, los servicios de correo o de moderación), y únicamente en la medida necesaria para prestar el servicio.',
    'Podemos divulgar información si la ley lo exige o para proteger la seguridad de las personas.',
  ]),
  _Seccion('Tus derechos', [
    'Puedes editar tus datos de perfil desde "Editar perfil" y ajustar su visibilidad desde "Privacidad".',
    'Puedes decidir qué avisos por correo recibir desde "Notificaciones".',
    'Puedes eliminar tu cuenta y, con ella, tus publicaciones y comentarios, desde Mi perfil.',
  ]),
  _Seccion('Conservación y eliminación', [
    'Conservamos tu información mientras tu cuenta esté activa.',
    'Cuando eliminas tu cuenta, se borran tu perfil, tus publicaciones y tus comentarios de forma permanente. Algunas copias de seguridad pueden tardar un tiempo en actualizarse.',
  ]),
  _Seccion('Menores de edad', [
    'Lulilu está pensada para personas que cumplen con la edad mínima requerida por su país para usar redes sociales. Si detectamos una cuenta de un menor sin la autorización correspondiente, podremos eliminarla.',
  ]),
  _Seccion('Cambios a esta política', [
    'Podemos actualizar esta política para reflejar mejoras en la app o cambios legales. Te recomendamos revisarla de vez en cuando.',
  ]),
  _Seccion('Contacto', [
    'Si tienes dudas sobre el uso de tu información, escríbenos a través del correo de soporte indicado en la app. Con gusto te ayudaremos.',
  ]),
];

class PoliticaInformacionScreen extends StatelessWidget {
  const PoliticaInformacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Política de información',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primaryContainer, scheme.surfaceContainer],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Cómo usamos, almacenamos y protegemos tus datos en Lulilu.',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              for (int i = 0; i < _secciones.length; i++)
                _tarjetaSeccion(context, numero: i + 1, seccion: _secciones[i]),

              const SizedBox(height: AppSpacing.sm),

              Center(
                child: Text(
                  'Última actualización: 2026',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaSeccion(
    BuildContext context, {
    required int numero,
    required _Seccion seccion,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  seccion.titulo,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final parrafo in seccion.parrafos)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                parrafo,
                style: AppTextStyles.body.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
