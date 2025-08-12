import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GestionredScreen extends StatefulWidget {
  const GestionredScreen({super.key});

  @override
  State<GestionredScreen> createState() => _GestionredScreenState();
}

class _GestionredScreenState extends State<GestionredScreen> {
  final supabase = Supabase.instance.client;
  final telefonoControl = TextEditingController();
  final nombreContactoControl = TextEditingController();
  final nombreEliminarControl = TextEditingController();

  bool _isLoading = false;
  String? _mensajeError;
  String? _mensajeExicto;
  List<dynamic> _listaContactos = [];

  @override
  void initState() {
    super.initState();
    _cargarRed();
  }

  Future<void> _cargarRed() async {
    final userId = supabase.auth.currentUser?.id;
    setState(() {
      _isLoading = true;
      _mensajeError = null;
      _mensajeExicto = null;
    });
    if (userId == null) {
      return;
    }
    try {
      final data = await supabase
          .from("contactos_sos")
          .select()
          .eq("user_id", userId);
      setState(() {
        _listaContactos = data as List;
      });
    } catch (e) {
      setState(() {
        _mensajeError = "Error cargando contactos";
        _mensajeExicto = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _agregarRed() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return;
    }
    try {
      await supabase.from("contactos_sos").insert({
        'nombre': nombreContactoControl,
        'telefono': telefonoControl,
        'user_id': userId,
      });
      setState(() {
        _mensajeExicto = "Usuario agregado exitosamente";
        _cargarRed();
      });
    } catch (e) {
      setState(() {
        _mensajeError = "Fallo agregando usuario ";
        _mensajeExicto = null;
      });
    }
  }

  Future<void> _eliminarDeRed() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return;
    }
    try {
      await supabase
          .from("contactos_sos")
          .delete()
          .eq("nombre", nombreEliminarControl);

      setState(() {
        _mensajeExicto = "Cotacto eliminado exictosamente";
        _cargarRed();
      });
    } catch (e) {
      setState(() {
        _mensajeError =
            "Fallo eliminado cotacto, verifique que el nombre este bien escrito ";
        _mensajeExicto = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Mi red de apoyo"),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mensajeError != null
                ? Center(
                    child: Text(
                      _mensajeExicto!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  )
                : _listaContactos.isEmpty
                ? Center(
                    child: Text(
                      "No hay contactos agregados",
                      style: const TextStyle(color: Colors.green),
                    ),
                  )
                : ListView.builder(
                    itemCount: _listaContactos.length,
                    itemBuilder: (context, i) {
                      final contacto = _listaContactos[i];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(contacto['nombre']),
                        subtitle: Text(contacto['telefono']),
                      );
                    },
                  ),
            const SizedBox(height: 16),

            Text("Agregar contacto"),
            TextField(
              controller: nombreContactoControl,
              decoration: const InputDecoration(
                labelText: 'Nombre de Contacto',
              ),
            ),
            TextField(
              controller: telefonoControl,
              decoration: const InputDecoration(labelText: 'Telefono'),
            ),

            if (_mensajeError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_mensajeExicto != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _mensajeExicto!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _agregarRed,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Agregar Contacto"),
            ),
            Text("Eliminar Contacto"),
            TextField(
              controller: nombreEliminarControl,
              decoration: const InputDecoration(
                labelText: 'Nombre de Contacto ',
              ),
            ),
            if (_mensajeError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_mensajeExicto != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _mensajeExicto!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _eliminarDeRed,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Eliminar Contacto"),
            ),
          ],
        ),
      ),
    );
  }
}
