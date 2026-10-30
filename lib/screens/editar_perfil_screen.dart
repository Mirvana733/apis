import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/perfil_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/fondo_lulilu.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final paternoController = TextEditingController();
  final maternoController = TextEditingController();
  final numeroController = TextEditingController();

  DateTime? fechaNacimiento;
  String correo = '';
  bool verificado = false;

  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    nombreController.dispose();
    paternoController.dispose();
    maternoController.dispose();
    numeroController.dispose();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      if (mounted) setState(() => cargando = false);
      return;
    }

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final datos = documento.data();

      if (datos != null) {
        nombreController.text = datos['nombre'] ?? '';
        paternoController.text = datos['apellidoPaterno'] ?? '';
        maternoController.text = datos['apellidoMaterno'] ?? '';
        numeroController.text = datos['numero'] ?? '';
        correo = datos['correo'] ?? usuario.email ?? '';
        verificado = datos['estadoVerificacion'] == 'verificado';

        final fecha = datos['fechaNacimiento'];
        if (fecha is Timestamp) {
          fechaNacimiento = fecha.toDate();
        }
      }
    } catch (e) {
      debugPrint('Error al cargar el perfil: $e');

      if (mounted) {
        mostrarMensaje('No se pudieron cargar tus datos.');
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaNacimiento ?? DateTime(2005),
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

  Future<void> guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (fechaNacimiento == null) {
      mostrarMensaje('Selecciona tu fecha de nacimiento.');
      return;
    }

    setState(() => guardando = true);

    try {
      await PerfilService.actualizarPerfil(
        nombre: nombreController.text,
        apellidoPaterno: paternoController.text,
        apellidoMaterno: maternoController.text,
        numero: numeroController.text,
        fechaNacimiento: fechaNacimiento!,
      );

      if (!mounted) return;

      mostrarMensaje('Perfil actualizado correctamente.');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error al guardar el perfil: $e');

      if (!mounted) return;

      setState(() => guardando = false);
      mostrarMensaje('No se pudieron guardar los cambios. Inténtalo de nuevo.');
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Editar perfil',
          style: AppTextStyles.headline.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: cargando
          ? const FondoLulilu(child: Center(child: CircularProgressIndicator()))
          : FondoLulilu(
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (verificado) _avisoVerificado(scheme),

                        campoTexto(
                          controller: nombreController,
                          label: 'Nombre',
                          icon: Icons.person_outline,
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa tu nombre';
                            }
                            return null;
                          },
                        ),

                        campoTexto(
                          controller: paternoController,
                          label: 'Apellido paterno',
                          icon: Icons.person_outline,
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa tu apellido paterno';
                            }
                            return null;
                          },
                        ),

                        campoTexto(
                          controller: maternoController,
                          label: 'Apellido materno',
                          icon: Icons.person_outline,
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa tu apellido materno';
                            }
                            return null;
                          },
                        ),

                        campoTexto(
                          controller: numeroController,
                          label: 'Número de celular',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Ingresa tu número';
                            }
                            if (valor.trim().length < 7) {
                              return 'Ingresa un número válido';
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
                                        : formatearFecha(fechaNacimiento!),
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

                        TextFormField(
                          initialValue: correo,
                          readOnly: true,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            helperText:
                                'El correo de acceso no se puede cambiar aquí.',
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: guardando ? null : guardar,
                            child: guardando
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: scheme.onSurfaceVariant,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('GUARDAR CAMBIOS'),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: guardando
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('CANCELAR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _avisoVerificado(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: scheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tu cuenta está verificada. Si cambias tu nombre o número de celular podrías necesitar verificarla de nuevo.',
              style: AppTextStyles.caption.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
