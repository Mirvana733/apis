import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendService {
  static const String baseUrl = String.fromEnvironment(
    'WORKER_URL',
    defaultValue: 'https://lulilu-api.<TU_SUBDOMINIO>.workers.dev',
  );

  static const String appSecret = String.fromEnvironment(
    'APP_SECRET',
    defaultValue: '',
  );

  static Future<Map<String, dynamic>> enviarCorreo({
    required String tipo,
    required String destinatario,
    String nombre = '',
  }) {
    return _post('/email', {
      'tipo': tipo,
      'destinatario': destinatario,
      'nombre': nombre,
    });
  }

  static Future<Map<String, dynamic>> moderarTexto({
    required String tipo,
    required String texto,
  }) {
    return _post('/moderar', {'tipo': tipo, 'texto': texto});
  }

  static Future<Map<String, dynamic>> _post(
    String ruta,
    Map<String, dynamic> datos,
  ) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl$ruta'),
          headers: {
            'Content-Type': 'application/json',
            if (appSecret.isNotEmpty) 'x-app-secret': appSecret,
          },
          body: jsonEncode(datos),
        )
        .timeout(const Duration(seconds: 40));

    final dynamic cuerpo = jsonDecode(respuesta.body);

    if (cuerpo is! Map<String, dynamic> || cuerpo['ok'] != true) {
      final mensaje = cuerpo is Map<String, dynamic>
          ? (cuerpo['error'] as String?)
          : null;

      throw Exception(mensaje ?? 'Error del servidor.');
    }

    return cuerpo;
  }
}
