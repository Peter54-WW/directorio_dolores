import 'dart:convert';

import 'package:directorio_dolores/datos/negocios_api.dart';
import 'package:directorio_dolores/dominio/negocio.dart';
import 'package:directorio_dolores/presentacion/negocios_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

NegociosViewModel vmCon(Future<http.Response> Function(http.Request) h) =>
    NegociosViewModel(NegociosApi(MockClient(h), 'http://prueba'));

void main() {
  test('cargar con datos termina en listo', () async {
    final vm = vmCon((_) async => http.Response(
        jsonEncode([
          {'id': 1, 'nombre': 'A', 'categoria': 'X'}
        ]),
        200));
    final estados = <Estado>[];
    vm.addListener(() => estados.add(vm.estado));
    await vm.cargar();
    expect(estados, [Estado.cargando, Estado.listo]);
    expect(vm.negocios.length, 1);
  });

  test('cargar con lista vacía termina en vacio', () async {
    final vm = vmCon((_) async => http.Response('[]', 200));
    await vm.cargar();
    expect(vm.estado, Estado.vacio);
  });

  test('cargar con error de servidor termina en error con mensaje', () async {
    final vm = vmCon((_) async => http.Response('', 500));
    await vm.cargar();
    expect(vm.estado, Estado.error);
    expect(vm.mensajeError, contains('500'));
  });

  test('eliminar quita el negocio de la lista', () async {
    final vm = vmCon((req) async => req.method == 'DELETE'
        ? http.Response('', 204)
        : http.Response(
            jsonEncode([
              {'id': 1, 'nombre': 'A', 'categoria': 'X'},
              {'id': 2, 'nombre': 'B', 'categoria': 'Y'},
            ]),
            200));
    await vm.cargar();
    await vm.eliminar(vm.negocios.first);
    expect(vm.negocios.map((n) => n.id), [2]);
  });

  test('alternarFavorito actualiza con la respuesta del servidor', () async {
    final vm = vmCon((req) async {
      if (req.method == 'PUT') {
        return http.Response(jsonEncode({'id': 1, 'nombre': 'A', 'categoria': 'X', 'favorito': true}), 200);
      }
      return http.Response(
          jsonEncode([
            {'id': 1, 'nombre': 'A', 'categoria': 'X'}
          ]),
          200);
    });
    await vm.cargar();
    await vm.alternarFavorito(vm.negocios.first);
    expect(vm.negocios.first.favorito, true);
  });

  test('si agregar falla por 400, el estado es error con "400" (reto)', () async {
    final vm = vmCon((req) async =>
        req.method == 'POST' ? http.Response('{"error":"x"}', 400) : http.Response('[]', 200));
    await vm.cargar();
    await vm.agregar(const Negocio(nombre: '', categoria: ''));
    expect(vm.estado, Estado.error);
    expect(vm.mensajeError, contains('400'));
  });

  test('si falla el favorito, la lista se conserva y hay aviso', () async {
    final vm = vmCon((req) async => req.method == 'PUT'
        ? http.Response('', 500)
        : http.Response(
            jsonEncode([
              {'id': 1, 'nombre': 'A', 'categoria': 'X'}
            ]),
            200));
    await vm.cargar();
    await vm.alternarFavorito(vm.negocios.first);
    expect(vm.estado, Estado.listo);
    expect(vm.negocios.first.favorito, false);
    expect(vm.aviso, contains('500'));
  });

  test('cambiarServidor usa la nueva URL y recarga', () async {
    final urls = <String>[];
    final vm = NegociosViewModel(NegociosApi(
        MockClient((req) async {
          urls.add('${req.url.scheme}://${req.url.host}:${req.url.port}');
          return http.Response('[]', 200);
        }),
        'http://10.0.2.2:3000'));
    await vm.cargar();
    await vm.cambiarServidor('http://192.168.1.50:3000');
    expect(urls, ['http://10.0.2.2:3000', 'http://192.168.1.50:3000']);
    expect(vm.urlServidor, 'http://192.168.1.50:3000');
  });
}
