import 'package:flutter/material.dart';

import '../dominio/negocio.dart';
import 'negocios_viewmodel.dart';

class PantallaNegocios extends StatefulWidget {
  final NegociosViewModel vm;
  final void Function(String url)? alGuardarServidor;

  const PantallaNegocios({super.key, required this.vm, this.alGuardarServidor});

  @override
  State<PantallaNegocios> createState() => _PantallaNegociosState();
}

class _PantallaNegociosState extends State<PantallaNegocios> {
  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_mostrarAviso);
    widget.vm.cargar();
  }

  @override
  void dispose() {
    widget.vm.removeListener(_mostrarAviso);
    super.dispose();
  }

  void _mostrarAviso() {
    final a = widget.vm.tomarAviso();
    if (a != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(a)));
    }
  }

  Future<void> _nuevo() async {
    final nombre = TextEditingController();
    final categoria = TextEditingController();
    final telefono = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo negocio'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: categoria, decoration: const InputDecoration(labelText: 'Categoría')),
          TextField(
              controller: telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      await widget.vm.agregar(Negocio(
          nombre: nombre.text.trim(), categoria: categoria.text.trim(), telefono: telefono.text.trim()));
    }
  }

  Future<void> _configurarServidor() async {
    final url = TextEditingController(text: widget.vm.urlServidor);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servidor de la API'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Emulador: http://10.0.2.2:3000\nCelular: http://IP-DE-TU-PC:3000'),
          TextField(
              key: const Key('url'),
              controller: url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Dirección')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Conectar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.vm.cambiarServidor(url.text);
      widget.alGuardarServidor?.call(widget.vm.urlServidor);
    } on FormatException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Directorio · Dolores Hidalgo'),
          actions: [
            IconButton(
                tooltip: 'Servidor', icon: const Icon(Icons.settings_ethernet), onPressed: _configurarServidor),
          ],
        ),
        floatingActionButton: FloatingActionButton(onPressed: _nuevo, child: const Icon(Icons.add)),
        body: switch (vm.estado) {
          Estado.inicial || Estado.cargando => const Center(child: CircularProgressIndicator()),
          Estado.error => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 64),
                  const SizedBox(height: 12),
                  Text(vm.mensajeError ?? 'Error', textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(vm.urlServidor, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: vm.cargar, child: const Text('Reintentar')),
                  TextButton(onPressed: _configurarServidor, child: const Text('Cambiar servidor')),
                ]),
              ),
            ),
          Estado.vacio => const Center(child: Text('Aún no hay negocios. ¡Agrega el primero!')),
          Estado.listo => RefreshIndicator(
              onRefresh: vm.cargar,
              child: ListView(children: [
                for (final n in vm.negocios)
                  Dismissible(
                    key: ValueKey(n.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => vm.eliminar(n),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(n.nombre.isEmpty ? '?' : n.nombre[0])),
                      title: Text(n.nombre),
                      subtitle: Text('${n.categoria} · ${n.telefono}'),
                      trailing: IconButton(
                        icon: Icon(n.favorito ? Icons.star : Icons.star_border,
                            color: n.favorito ? Colors.amber : null),
                        onPressed: () => vm.alternarFavorito(n),
                      ),
                    ),
                  ),
              ]),
            ),
        },
      ),
    );
  }
}
