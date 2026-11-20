import 'package:directorio_dolores/datos/config_api.dart';
import 'package:directorio_dolores/dominio/negocio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Negocio', () {
    test('desdeJson lee todos los campos', () {
      final n = Negocio.desdeJson({
        'id': 1,
        'nombre': 'Nieves de la Plaza',
        'categoria': 'Nevería',
        'telefono': '418-100-0001',
        'favorito': true,
      });
      expect(n.id, 1);
      expect(n.nombre, 'Nieves de la Plaza');
      expect(n.favorito, true);
    });

    test('campos opcionales ausentes usan valores por omisión', () {
      final n = Negocio.desdeJson({'id': 2, 'nombre': 'X', 'categoria': 'Y'});
      expect(n.telefono, '');
      expect(n.favorito, false);
    });

    test('aJson no manda id cuando es nuevo', () {
      const n = Negocio(nombre: 'X', categoria: 'Y');
      expect(n.aJson().containsKey('id'), false);
    });

    test('copiarCon cambia solo el favorito', () {
      const n = Negocio(id: 3, nombre: 'X', categoria: 'Y');
      final f = n.copiarCon(favorito: true);
      expect(f.favorito, true);
      expect(f.nombre, 'X');
      expect(f.id, 3);
    });
  });

  group('Configuración de la URL', () {
    test('normaliza la URL escrita por el usuario', () {
      expect(normalizarUrl('192.168.1.50:3000'), 'http://192.168.1.50:3000');
      expect(normalizarUrl(' http://10.0.2.2:3000/ '), 'http://10.0.2.2:3000');
    });

    test('rechaza URLs sin host', () {
      expect(() => normalizarUrl(''), throwsFormatException);
      expect(() => normalizarUrl('http://'), throwsFormatException);
    });
  });
}
