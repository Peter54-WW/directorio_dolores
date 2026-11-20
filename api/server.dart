// Misma API que server.js, pero en Dart (viene incluido con Flutter: no hay que instalar Node).
// Uso:  dart run server.dart        (puerto 3000, o variable de entorno PORT)
import 'dart:convert';
import 'dart:io';

var siguienteId = 6;
final negocios = <Map<String, dynamic>>[
  {'id': 1, 'nombre': 'Nieves de la Plaza', 'categoria': 'Nevería', 'telefono': '418-100-0001', 'favorito': true},
  {'id': 2, 'nombre': 'Talavera La Esperanza', 'categoria': 'Artesanías', 'telefono': '418-100-0002', 'favorito': false},
  {'id': 3, 'nombre': 'Tacos Don Chema', 'categoria': 'Comida', 'telefono': '418-100-0003', 'favorito': false},
  {'id': 4, 'nombre': 'Dulces Cajeta Real', 'categoria': 'Dulcería', 'telefono': '418-100-0004', 'favorito': true},
  {'id': 5, 'nombre': 'Papelería El Cura', 'categoria': 'Papelería', 'telefono': '418-100-0005', 'favorito': false},
];

Future<void> responder(HttpRequest req, int status, [Object? datos]) async {
  final r = req.response
    ..statusCode = status
    ..headers.set('Content-Type', 'application/json; charset=utf-8')
    ..headers.set('Access-Control-Allow-Origin', '*')
    ..headers.set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS')
    ..headers.set('Access-Control-Allow-Headers', 'Content-Type');
  if (datos != null) r.add(utf8.encode(jsonEncode(datos)));
  await r.close();
}

Future<Map<String, dynamic>> leerCuerpo(HttpRequest req) async {
  final texto = await utf8.decoder.bind(req).join();
  return texto.isEmpty ? {} : jsonDecode(texto) as Map<String, dynamic>;
}

Future<void> atender(HttpRequest req) async {
  final partes = req.uri.pathSegments.where((s) => s.isNotEmpty).toList();
  stdout.writeln('${DateTime.now().toIso8601String().substring(11, 19)} ${req.method} ${req.uri.path}');

  if (req.method == 'OPTIONS') return responder(req, 204);
  if (req.uri.path == '/salud') return responder(req, 200, {'ok': true});
  if (partes.isEmpty || partes[0] != 'negocios') return responder(req, 404, {'error': 'Ruta no encontrada'});
  final id = partes.length > 1 ? int.tryParse(partes[1]) : null;

  try {
    if (req.method == 'GET' && id == null) {
      final q = (req.uri.queryParameters['q'] ?? '').toLowerCase();
      return responder(req, 200, negocios.where((n) => (n['nombre'] as String).toLowerCase().contains(q)).toList());
    }
    if (req.method == 'GET') {
      final n = negocios.where((x) => x['id'] == id).firstOrNull;
      return n != null ? responder(req, 200, n) : responder(req, 404, {'error': 'No existe'});
    }
    if (req.method == 'POST') {
      final d = await leerCuerpo(req);
      if ((d['nombre'] ?? '') == '' || (d['categoria'] ?? '') == '') {
        return responder(req, 400, {'error': 'nombre y categoria son obligatorios'});
      }
      final nuevo = {
        'id': siguienteId++,
        'nombre': d['nombre'],
        'categoria': d['categoria'],
        'telefono': d['telefono'] ?? '',
        'favorito': d['favorito'] == true,
      };
      negocios.add(nuevo);
      return responder(req, 201, nuevo);
    }
    if (req.method == 'PUT') {
      final i = negocios.indexWhere((x) => x['id'] == id);
      if (i < 0) return responder(req, 404, {'error': 'No existe'});
      final d = await leerCuerpo(req);
      negocios[i] = {...negocios[i], ...d, 'id': id};
      return responder(req, 200, negocios[i]);
    }
    if (req.method == 'DELETE') {
      final i = negocios.indexWhere((x) => x['id'] == id);
      if (i < 0) return responder(req, 404, {'error': 'No existe'});
      negocios.removeAt(i);
      return responder(req, 204);
    }
    return responder(req, 405, {'error': 'Método no permitido'});
  } on FormatException {
    return responder(req, 400, {'error': 'JSON inválido'});
  }
}

Future<void> main() async {
  final puerto = int.tryParse(Platform.environment['PORT'] ?? '') ?? 3000;
  // anyIPv4 = 0.0.0.0: permite que el celular (misma red Wi-Fi) llegue a tu computadora.
  final servidor = await HttpServer.bind(InternetAddress.anyIPv4, puerto);
  stdout.writeln('API lista en http://localhost:$puerto/negocios');
  await for (final req in servidor) {
    atender(req);
  }
}
