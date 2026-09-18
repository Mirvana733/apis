import 'dart:io';

String extensionMedia(File archivo) {
  final nombre = archivo.path.toLowerCase();
  if (nombre.endsWith('.png')) {
    return '.png';
  }
  return '.jpg';
}

String contentTypeMedia(File archivo) {
  return extensionMedia(archivo) == '.png' ? 'image/png' : 'image/jpeg';
}