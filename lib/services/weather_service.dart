import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  static const double latitud = -17.3935;
  static const double longitud = -66.1568;

  static Future<Map<String, dynamic>> obtenerClima() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitud'
      '&longitude=$longitud'
      '&current=temperature_2m,weather_code,is_day'
      '&temperature_unit=celsius'
      '&timezone=America%2FLa_Paz',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener el clima.');
    }

    final data = jsonDecode(response.body);

    return {
      'temperatura': data['current']['temperature_2m'],
      'codigo': data['current']['weather_code'],
      'esDeDia': data['current']['is_day'] == 1,
    };
  }

  static String descripcionClima(int codigo) {
    if (codigo == 0) {
      return 'Despejado';
    } else if (codigo <= 3) {
      return 'Parcialmente nublado';
    } else if (codigo <= 48) {
      return 'Nublado';
    } else if (codigo <= 67) {
      return 'Lluvia';
    } else if (codigo <= 77) {
      return 'Nieve';
    } else if (codigo <= 82) {
      return 'Lluvias';
    } else if (codigo <= 86) {
      return 'Nieve';
    } else {
      return 'Tormenta';
    }
  }

  static String iconoClima(int codigo, bool esDeDia) {
    if (codigo == 0) {
      return esDeDia ? '☀️' : '🌙';
    } else if (codigo <= 3) {
      return esDeDia ? '⛅' : '🌙☁️';
    } else if (codigo <= 48) {
      return '☁️';
    } else if (codigo <= 67) {
      return '🌧️';
    } else if (codigo <= 77) {
      return '❄️';
    } else if (codigo <= 82) {
      return '🌦️';
    } else if (codigo <= 86) {
      return '❄️';
    } else {
      return '⛈️';
    }
  }
}