import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'datos/config_api.dart';
import 'datos/negocios_api.dart';
import 'presentacion/negocios_viewmodel.dart';
import 'presentacion/pantalla_negocios.dart';

const _claveUrl = 'url_api';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // composition root: la URL guardada gana; si no hay, la de la plataforma
  final api = NegociosApi(http.Client(), prefs.getString(_claveUrl) ?? urlBaseApi());
  runApp(MaterialApp(
    title: 'Directorio Dolores',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
    home: PantallaNegocios(
      vm: NegociosViewModel(api),
      alGuardarServidor: (url) => prefs.setString(_claveUrl, url),
    ),
  ));
}
