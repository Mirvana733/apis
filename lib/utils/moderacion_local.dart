const Set<String> _palabrasOfensivas = {
  'mierda',
  'puta',
  'puto',
  'putas',
  'putos',
  'pendejo',
  'pendeja',
  'pendejos',
  'pendejas',
  'cabron',
  'cabrona',
  'coño',
  'joder',
  'jodete',
  'jodido',
  'jodida',
  'chucha',
  'verga',
  'gilipollas',
  'imbecil',
  'pajero',
  'pajera',
  'maricon',
  'marica',
  'culiao',
  'culiado',
  'weon',
  'huevon',
  'huevona',
  'cagon',
  'cagona',
  'mamada',
  'perra',
  'zorra',
  'conchetumare',
  'aweonao',
  'subnormal',
  'estupido',
  'tarado',
};

String _normalizar(String valor) {
  const conAcentos = 'áéíóúüñÁÉÍÓÚÜÑ';
  const sinAcentos = 'aeiouunAEIOUUN';

  final buffer = StringBuffer();

  for (final letra in valor.toLowerCase().split('')) {
    final indice = conAcentos.indexOf(letra);
    buffer.write(indice >= 0 ? sinAcentos[indice] : letra);
  }

  return buffer.toString();
}

String? palabraOfensiva(String texto) {
  final normalizado = _normalizar(texto.trim());

  if (normalizado.isEmpty) return null;

  final palabras = normalizado
      .split(RegExp(r'[^a-z0-9]+'))
      .where((p) => p.isNotEmpty);

  for (final palabra in palabras) {
    if (_palabrasOfensivas.contains(palabra)) return palabra;
  }

  return null;
}
