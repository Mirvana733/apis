import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/notificaciones_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/estrella_lulilu.dart';
import '../widgets/fondo_lulilu.dart';
import 'bienvenida_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // ==============================
  // CAMPOS DEL REGISTRO
  // ==============================

  final nombreController = TextEditingController();
  final paternoController = TextEditingController();
  final maternoController = TextEditingController();
  final correoController = TextEditingController();
  final numeroController = TextEditingController();
  final passwordController = TextEditingController();

  DateTime? fechaNacimiento;

  File? fotoCI;

  CameraController? cameraController;

  bool camaraActiva = false;
  bool iniciandoCamara = false;
  bool mostrarPassword = false;
  bool registrando = false;

  final ImagePicker picker = ImagePicker();

  @override
  void dispose() {
    nombreController.dispose();
    paternoController.dispose();
    maternoController.dispose();
    correoController.dispose();
    numeroController.dispose();
    passwordController.dispose();

    cameraController?.dispose();

    super.dispose();
  }

  // ==============================
  // FECHA DE NACIMIENTO
  // ==============================

  Future<void> seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Selecciona tu fecha de nacimiento',
    );

    if (fecha != null) {
      setState(() {
        fechaNacimiento = fecha;
      });
    }
  }

  // ==============================
  // TOMAR FOTO DE CI
  // ==============================

  Future<void> tomarFotoCI() async {
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (imagen != null) {
        setState(() {
          fotoCI = File(imagen.path);
        });
      }
    } catch (e) {
      mostrarMensaje('No se pudo tomar la foto de la CI.');
    }
  }

  // ==============================
  // SUBIR FOTO DE CI
  // ==============================

  Future<void> subirFotoCI() async {
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imagen != null) {
        setState(() {
          fotoCI = File(imagen.path);
        });
      }
    } catch (e) {
      mostrarMensaje('No se pudo seleccionar la foto.');
    }
  }

  // ==============================
  // VERIFICACIÓN DE IDENTIDAD
  // ==============================

  Future<void> abrirVerificacionIdentidad() async {
    if (iniciandoCamara || camaraActiva) return;

    setState(() {
      iniciandoCamara = true;
    });

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        mostrarMensaje('No se encontró ninguna cámara.');
        return;
      }

      CameraDescription camaraFrontal = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          camaraFrontal = camera;
          break;
        }
      }

      final controller = CameraController(
        camaraFrontal,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      cameraController = controller;

      setState(() {
        camaraActiva = true;
      });
    } catch (e) {
      mostrarMensaje('No se pudo iniciar la cámara.');
    } finally {
      if (mounted) {
        setState(() {
          iniciandoCamara = false;
        });
      }
    }
  }

  // ==============================
  // CERRAR CÁMARA
  // ==============================

  Future<void> cerrarCamara() async {
    final controller = cameraController;

    cameraController = null;

    if (mounted) {
      setState(() {
        camaraActiva = false;
      });
    }

    await controller?.dispose();
  }

  // ==============================
  // REGISTRAR USUARIO
  // ==============================

  Future<void> registrarUsuario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (fechaNacimiento == null) {
      mostrarMensaje('Selecciona tu fecha de nacimiento.');
      return;
    }

    if (fotoCI == null) {
      mostrarMensaje('Debes agregar una foto de tu CI.');
      return;
    }

    if (!camaraActiva) {
      mostrarMensaje('Debes realizar la verificación de identidad.');
      return;
    }

    setState(() {
      registrando = true;
    });

    User? usuarioCreado;

    try {
      // ==============================
      // 1. CREAR USUARIO EN FIREBASE AUTH
      // ==============================

      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: correoController.text.trim(),
            password: passwordController.text,
          );

      usuarioCreado = credencial.user;

      if (usuarioCreado == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      // ==============================
      // 2. GUARDAR DATOS EN FIRESTORE
      // ==============================

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuarioCreado.uid)
          .set({
            'uid': usuarioCreado.uid,
            'nombre': nombreController.text.trim(),
            'apellidoPaterno': paternoController.text.trim(),
            'apellidoMaterno': maternoController.text.trim(),
            'fechaNacimiento': Timestamp.fromDate(fechaNacimiento!),
            'correo': correoController.text.trim(),
            'numero': numeroController.text.trim(),
            'rol': 'usuario',
            'verificacionIdentidad': false,
            'estadoVerificacion': 'pendiente',
            'fechaRegistro': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        await cerrarCamara();
      }

      fotoCI = null;

      if (!mounted) return;

      setState(() {
        registrando = false;
      });

      NotificacionesService.enviarCorreoBienvenida(
        correo: correoController.text.trim(),
        nombre: nombreController.text.trim(),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('¡Registro exitoso! 🎉'),
            content: const Text('Tu cuenta fue creada correctamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const BienvenidaScreen()),
                  );
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          registrando = false;
        });
      }

      if (e.code == 'email-already-in-use') {
        mostrarMensaje('Ese correo ya está registrado.');
      } else if (e.code == 'invalid-email') {
        mostrarMensaje('El correo electrónico no es válido.');
      } else if (e.code == 'weak-password') {
        mostrarMensaje('La contraseña es demasiado débil.');
      } else {
        mostrarMensaje('No se pudo crear la cuenta.');
      }
    } on FirebaseException catch (e) {
      if (usuarioCreado != null) {
        try {
          await usuarioCreado.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          registrando = false;
        });
      }

      if (e.code == 'permission-denied') {
        mostrarMensaje(
          'Firestore no permite guardar los datos. Revisa las reglas de seguridad.',
        );
      } else {
        mostrarMensaje(
          'La cuenta se creó, pero no se pudieron guardar los datos.',
        );
      }
    } catch (e) {
      if (usuarioCreado != null) {
        try {
          await usuarioCreado.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          registrando = false;
        });
      }

      mostrarMensaje('Ocurrió un error durante el registro.');
    }
  }

  // ==============================
  // MENSAJE
  // ==============================

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  // ==============================
  // CAMPO DE TEXTO
  // ==============================

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  // ==============================
  // FOTO DE CI
  // ==============================

  Widget tarjetaFotoCI() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.badge_outlined,
                  color: scheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Foto de tu CI',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'La imagen se utilizará temporalmente para la verificación de identidad y no se guardará como parte de tu perfil.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (fotoCI != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.file(
                fotoCI!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          if (fotoCI != null) const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: tomarFotoCI,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tomar foto'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: subirFotoCI,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Subir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================
  // VERIFICACIÓN DE IDENTIDAD
  // ==============================

  Widget tarjetaVerificacion() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.face_outlined,
                  color: scheme.onSecondaryContainer,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Verificación de identidad',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Realiza la verificación mediante la cámara frontal.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!camaraActiva)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: iniciandoCamara ? null : abrirVerificacionIdentidad,
                icon: iniciandoCamara
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          // Botón deshabilitado mientras abre la cámara.
                          color: scheme.onSurfaceVariant,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.face_outlined),
                label: Text(
                  iniciandoCamara
                      ? 'Abriendo cámara...'
                      : 'VERIFICACIÓN DE IDENTIDAD',
                ),
              ),
            ),
          if (camaraActiva &&
              cameraController != null &&
              cameraController!.value.isInitialized) ...[
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coloca tu rostro frente a la cámara.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: cerrarCamara,
                icon: const Icon(Icons.close),
                label: const Text('Cerrar cámara'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================
  // INTERFAZ
  // ==============================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: Text(
          'Crear cuenta',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: FondoLulilu(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer,
                          scheme.surfaceContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: EstrellaLulilu(
                              size: 26,
                              color: scheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenido a Lulilu!',
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: 22,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Completa tus datos para crear tu cuenta.',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  campoTexto(
                    controller: nombreController,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      return null;
                    },
                  ),

                  campoTexto(
                    controller: paternoController,
                    label: 'Apellido paterno',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu apellido paterno';
                      }
                      return null;
                    },
                  ),

                  campoTexto(
                    controller: maternoController,
                    label: 'Apellido materno',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu apellido materno';
                      }
                      return null;
                    },
                  ),

                  Text(
                    'Fecha de nacimiento',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  InkWell(
                    onTap: seleccionarFecha,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              fechaNacimiento == null
                                  ? 'Seleccionar fecha'
                                  : '${fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                                        '${fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                                        '${fechaNacimiento!.year}',
                              style: AppTextStyles.body.copyWith(
                                color: fechaNacimiento == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  campoTexto(
                    controller: correoController,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo';
                      }

                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }

                      return null;
                    },
                  ),

                  campoTexto(
                    controller: numeroController,
                    label: 'Número de celular',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu número';
                      }

                      if (value.length < 7) {
                        return 'Ingresa un número válido';
                      }

                      return null;
                    },
                  ),

                  tarjetaFotoCI(),

                  tarjetaVerificacion(),

                  campoTexto(
                    controller: passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: !mostrarPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }

                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }

                      return null;
                    },
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: mostrarPassword,
                        onChanged: (value) {
                          setState(() {
                            mostrarPassword = value ?? false;
                          });
                        },
                      ),
                      Text(
                        'Mostrar contraseña',
                        style: AppTextStyles.body.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registrando ? null : registrarUsuario,
                      child: registrando
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                // Botón deshabilitado durante el registro.
                                color: scheme.onSurfaceVariant,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('REGISTRARSE'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('¿Ya tienes una cuenta? Inicia sesión'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
