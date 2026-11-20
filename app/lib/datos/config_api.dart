import 'dart:io' show Platform;

/// Dirección de la API según dónde corre la app.
/// - Emulador Android: 10.0.2.2 es "la computadora anfitriona".
/// - Simulador iOS / escritorio: localhost.
/// - Celular real: se escribe la IP de la PC en el engrane de la app, o
///   flutter run --dart-define=API_URL=http://192.168.1.50:3000
String urlBaseApi() {
  const manual = String.fromEnvironment('API_URL');
  if (manual.isNotEmpty) return manual;
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

/// Limpia lo que escribe el usuario: agrega http:// y quita la diagonal final.
String normalizarUrl(String texto) {
  var t = texto.trim();
  if (t.isEmpty) throw const FormatException('Escribe la dirección del servidor');
  if (!t.startsWith('http://') && !t.startsWith('https://')) t = 'http://$t';
  while (t.endsWith('/')) {
    t = t.substring(0, t.length - 1);
  }
  final uri = Uri.tryParse(t);
  if (uri == null || uri.host.isEmpty) throw FormatException('Dirección inválida: $texto');
  return t;
}
