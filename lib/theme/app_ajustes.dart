import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de apariencia de la aplicación.
///
/// Es un singleton porque `main.dart` lo consulta antes de construir el
/// [MaterialApp] y la pantalla de Configuración lo modifica después. Al ser un
/// [ChangeNotifier], cualquier pantalla que lo escuche se reconstruye.
///
/// Se guarda con `shared_preferences`: son ajustes del dispositivo, no del
/// usuario, así que no van a Firestore.
class AppAjustes extends ChangeNotifier {
  AppAjustes._();

  static final AppAjustes instancia = AppAjustes._();

  static const String _claveTema = 'ajustes_tema';
  static const String _claveEscalaTexto = 'ajustes_escala_texto';

  ThemeMode _tema = ThemeMode.system;
  double _escalaTexto = 1.0;

  ThemeMode get tema => _tema;

  double get escalaTexto => _escalaTexto;

  /// Carga lo guardado en el dispositivo. Si falla, conserva los valores por
  /// defecto (tema del sistema, tamaño normal).
  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final temaGuardado = prefs.getString(_claveTema);
      _tema = ThemeMode.values.firstWhere(
        (modo) => modo.name == temaGuardado,
        orElse: () => ThemeMode.system,
      );

      _escalaTexto = prefs.getDouble(_claveEscalaTexto) ?? 1.0;
    } catch (e) {
      debugPrint('No se pudieron cargar los ajustes: $e');
    }

    notifyListeners();
  }

  Future<void> cambiarTema(ThemeMode tema) async {
    if (_tema == tema) return;

    _tema = tema;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveTema, tema.name);
    } catch (e) {
      debugPrint('No se pudo guardar el tema: $e');
    }
  }

  Future<void> cambiarEscalaTexto(double escala) async {
    if (_escalaTexto == escala) return;

    _escalaTexto = escala;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_claveEscalaTexto, escala);
    } catch (e) {
      debugPrint('No se pudo guardar el tamaño de texto: $e');
    }
  }
}
