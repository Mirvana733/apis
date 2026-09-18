import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/notificaciones_service.dart';
import '../theme/app_colors.dart';
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
      mostrarMensaje(
        'Selecciona tu fecha de nacimiento.',
      );
      return;
    }

    if (fotoCI == null) {
      mostrarMensaje(
        'Debes agregar una foto de tu CI.',
      );
      return;
    }

    if (!camaraActiva) {
      mostrarMensaje(
        'Debes realizar la verificación de identidad.',
      );
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

      final credencial =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
            title: const Text(
              '¡Registro exitoso! 🎉',
            ),
            content: const Text(
              'Tu cuenta fue creada correctamente.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const BienvenidaScreen(),
                    ),
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
        mostrarMensaje(
          'Ese correo ya está registrado.',
        );
      } else if (e.code == 'invalid-email') {
        mostrarMensaje(
          'El correo electrónico no es válido.',
        );
      } else if (e.code == 'weak-password') {
        mostrarMensaje(
          'La contraseña es demasiado débil.',
        );
      } else {
        mostrarMensaje(
          'No se pudo crear la cuenta.',
        );
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

      mostrarMensaje(
        'Ocurrió un error durante el registro.',
      );
    }
  }

  // ==============================
  // MENSAJE
  // ==============================

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ==============================
  // FOTO DE CI
  // ==============================

  Widget tarjetaFotoCI() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.grey300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.badge_outlined,
                color: Color.fromARGB(255, 30, 50, 233),
              ),
              SizedBox(width: 10),
              Text(
                'Foto de tu CI',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'La imagen se utilizará temporalmente para la verificación de identidad y no se guardará como parte de tu perfil.',
            style: TextStyle(
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 15),
          if (fotoCI != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                fotoCI!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          if (fotoCI != null)
            const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: tomarFotoCI,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: subirFotoCI,
                  icon: const Icon(Icons.photo_library),
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.grey300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.face,
                color: Color.fromARGB(255, 44, 30, 233),
              ),
              SizedBox(width: 10),
              Text(
                'Verificación de identidad',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Realiza la verificación mediante la cámara frontal.',
            style: TextStyle(
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 15),
          if (!camaraActiva)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: iniciandoCamara
                    ? null
                    : abrirVerificacionIdentidad,
                icon: iniciandoCamara
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.face),
                label: Text(
                  iniciandoCamara
                      ? 'Abriendo cámara...'
                      : 'VERIFICACIÓN DE IDENTIDAD',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 86, 89, 245),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          if (camaraActiva &&
              cameraController != null &&
              cameraController!.value.isInitialized) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(
                  cameraController!,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Coloca tu rostro frente a la cámara.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear cuenta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 168, 220, 250),
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido a Lulilu! ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tus datos para crear tu cuenta.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 25),

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

                const Text(
                  'Fecha de nacimiento',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: seleccionarFecha,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Color.fromARGB(255, 146, 157, 250),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          fechaNacimiento == null
                              ? 'Seleccionar fecha'
                              : '${fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                                '${fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                                '${fechaNacimiento!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: fechaNacimiento == null
                                ? AppColors.grey600
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                    const Text(
                      'Mostrar contraseña',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: registrando
                        ? null
                        : registrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 95, 207),
                      foregroundColor: const Color.fromARGB(255, 188, 241, 245),
                      disabledBackgroundColor: AppColors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: registrando
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'REGISTRARSE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '¿Ya tienes una cuenta? Inicia sesión',
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}