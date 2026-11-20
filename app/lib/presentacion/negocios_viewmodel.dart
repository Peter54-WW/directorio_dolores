import 'package:flutter/foundation.dart';

import '../datos/config_api.dart';
import '../datos/negocios_api.dart';
import '../dominio/negocio.dart';

enum Estado { inicial, cargando, listo, vacio, error }

class NegociosViewModel extends ChangeNotifier {
  final NegociosApi api;
  Estado estado = Estado.inicial;
  List<Negocio> negocios = [];
  String? mensajeError;

  /// Error que NO tumba la lista (p. ej. falló marcar favorito): se muestra en un SnackBar.
  String? aviso;

  NegociosViewModel(this.api);

  String get urlServidor => api.baseUrl;

  Future<void> cargar({String busqueda = ''}) async {
    estado = Estado.cargando;
    mensajeError = null;
    notifyListeners();
    try {
      negocios = await api.listar(busqueda: busqueda);
      estado = negocios.isEmpty ? Estado.vacio : Estado.listo;
    } catch (e) {
      mensajeError = e.toString();
      estado = Estado.error;
    }
    notifyListeners();
  }

  Future<void> agregar(Negocio n) async {
    try {
      await api.crear(n);
      await cargar();
    } catch (e) {
      mensajeError = e.toString();
      estado = Estado.error;
      notifyListeners();
    }
  }

  Future<void> eliminar(Negocio n) async {
    try {
      await api.eliminar(n.id!);
      negocios = negocios.where((x) => x.id != n.id).toList();
      estado = negocios.isEmpty ? Estado.vacio : Estado.listo;
    } catch (e) {
      mensajeError = e.toString();
      estado = Estado.error;
    }
    notifyListeners();
  }

  Future<void> alternarFavorito(Negocio n) async {
    try {
      final nuevo = await api.actualizar(n.copiarCon(favorito: !n.favorito));
      negocios = [for (final x in negocios) x.id == nuevo.id ? nuevo : x];
    } catch (e) {
      // En el estado "listo" la pantalla no muestra mensajeError: se usa un aviso (SnackBar).
      aviso = e.toString();
    }
    notifyListeners();
  }

  /// Permite apuntar a la IP de la PC desde el celular sin recompilar.
  Future<void> cambiarServidor(String texto) async {
    api.baseUrl = normalizarUrl(texto);
    await cargar();
  }

  String? tomarAviso() {
    final a = aviso;
    aviso = null;
    return a;
  }
}
