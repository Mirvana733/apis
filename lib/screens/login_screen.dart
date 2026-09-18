import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notificaciones_service.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import 'pantalla_principal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  bool iniciandoSesion = false;
  bool mostrarPassword = false;
  Map<String, dynamic>? clima;
  bool cargandoClima = true;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    cargarClima();
  }

  Future<void> cargarClima() async {
    try {
      final resultado = await WeatherService.obtenerClima();

      if (!mounted) return;

      setState(() {
        clima = resultado;
        cargandoClima = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoClima = false;
      });
    }
  }

  // ==========================================
  // INICIAR SESIÓN
  // ==========================================

  Future<void> iniciarSesion() async {
    FocusScope.of(context).unfocus();

    final correo = correoController.text.trim();
    final password = passwordController.text;

    if (correo.isEmpty) {
      mostrarMensaje('Ingresa tu correo electrónico.');
      return;
    }

    if (!correo.contains('@')) {
      mostrarMensaje('Ingresa un correo electrónico válido.');
      return;
    }

    if (password.isEmpty) {
      mostrarMensaje('Ingresa tu contraseña.');
      return;
    }

    setState(() {
      iniciandoSesion = true;
    });

    try {
      // ==========================================
      // INICIAR SESIÓN EN FIREBASE AUTH
      // ==========================================

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );

      NotificacionesService.notificarNuevoIngreso();

      // ==========================================
      // ENTRAR A LA PANTALLA PRINCIPAL
      // ==========================================

      if (!mounted) return;

      setState(() {
        iniciandoSesion = false;
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PantallaPrincipal(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        iniciandoSesion = false;
      });

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        mostrarMensaje(
          'El correo o la contraseña son incorrectos.',
        );
      } else if (e.code == 'invalid-email') {
        mostrarMensaje(
          'El correo electrónico no es válido.',
        );
      } else if (e.code == 'user-disabled') {
        mostrarMensaje(
          'Esta cuenta está deshabilitada.',
        );
      } else {
        mostrarMensaje(
          'No se pudo iniciar sesión.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        iniciandoSesion = false;
      });

      mostrarMensaje(
        'Ocurrió un error al iniciar sesión.',
      );
    }
  }

  // ==========================================
  // MENSAJE
  // ==========================================

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // INTERFAZ
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 69, 125, 245),
                AppColors.cyanStrong,
                AppColors.orange,
              ],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido a Lulilu ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.blueDark,
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // CLIMA
            // ==========================================

            if (cargandoClima)
              const SizedBox(
                height: 70,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.cyanStrong,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (clima != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.profileBackground1,
                      AppColors.profileBackground3,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      WeatherService.iconoClima(
                        clima!['codigo'] as int,
                        clima!['esDeDia'] as bool,
                      ),
                      style: const TextStyle(
                        fontSize: 38,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cochabamba',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blueDark,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${clima!['temperatura']} °C · '
                          '${WeatherService.descripcionClima(
                            clima!['codigo'] as int,
                          )}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // ==========================================
            // CORREO ELECTRÓNICO
            // ==========================================

            TextField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              enabled: !iniciandoSesion,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.blueDark,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.cyanStrong,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.cyanStrong,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // CONTRASEÑA
            // ==========================================

            TextField(
              controller: passwordController,
              obscureText: !mostrarPassword,
              enabled: !iniciandoSesion,
              onSubmitted: (_) => iniciarSesion(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(
                  Icons.lock,
                  color: AppColors.blueDark,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      mostrarPassword = !mostrarPassword;
                    });
                  },
                  color: AppColors.cyanDark,
                  icon: Icon(
                    mostrarPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.cyanStrong,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.cyanStrong,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // BOTÓN INICIAR SESIÓN
            // ==========================================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.blueDark,
                      AppColors.cyanStrong,
                      AppColors.orange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ElevatedButton(
                  onPressed:
                      iniciandoSesion ? null : iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: iniciandoSesion
                      ? const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}