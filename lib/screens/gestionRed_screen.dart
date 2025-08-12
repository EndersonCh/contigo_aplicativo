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
  String? _mensajeExito;
  List<dynamic> _listaContactos = [];

  @override
  void initState() {
    super.initState();
    _cargarRed();
  }

  Future<void> _cargarRed() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _mensajeError = null;
      _mensajeExito = null;
    });

    try {
      final data = await supabase
          .from("contactos_sos")
          .select()
          .eq("user_id", userId);

      setState(() {
        _listaContactos = data;
      });
    } catch (e) {
      setState(() {
        _mensajeError = "Error cargando contactos";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarRed() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (nombreContactoControl.text.isEmpty || telefonoControl.text.isEmpty) {
      setState(() => _mensajeError = "Complete todos los campos");
      return;
    }

    try {
      await supabase.from("contactos_sos").insert({
        'nombre': nombreContactoControl.text,
        'telefono': telefonoControl.text,
        'user_id': userId,
      });

      setState(() {
        _mensajeExito = "Usuario agregado exitosamente";
        nombreContactoControl.clear();
        telefonoControl.clear();
      });

      _cargarRed();
    } catch (e) {
      setState(() {
        _mensajeError = "Fallo agregando usuario";
      });
    }
  }

  Future<void> _eliminarDeRed() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (nombreEliminarControl.text.isEmpty) {
      setState(() => _mensajeError = "Ingrese un nombre para eliminar");
      return;
    }

    try {
      await supabase
          .from("contactos_sos")
          .delete()
          .eq("user_id", userId)
          .eq("nombre", nombreEliminarControl.text);

      setState(() {
        _mensajeExito = "Contacto eliminado exitosamente";
        nombreEliminarControl.clear();
      });

      _cargarRed();
    } catch (e) {
      setState(() {
        _mensajeError =
            "Fallo eliminando contacto. Verifique que el nombre esté bien escrito.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Ajusta pantalla cuando abre teclado
      appBar: AppBar(
        title: const Text("Mi red de apoyo"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView( // Permite scroll en toda la pantalla
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Lista de contactos
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listaContactos.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay contactos agregados",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _listaContactos.length,
                        itemBuilder: (context, i) {
                          final contacto = _listaContactos[i];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 4),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                contacto['nombre'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(contacto['telefono']),
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 10),

            // Mensajes de estado
            if (_mensajeError != null)
              Text(_mensajeError!, style: const TextStyle(color: Colors.red)),
            if (_mensajeExito != null)
              Text(_mensajeExito!, style: const TextStyle(color: Colors.green)),

            const Divider(height: 30),

            // Agregar contacto
            const Text(
              "Agregar contacto",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextField(
              controller: nombreContactoControl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            TextField(
              controller: telefonoControl,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _agregarRed,
              icon: const Icon(Icons.add),
              label: const Text("Agregar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),

            const Divider(height: 30),

            // Eliminar contacto
            const Text(
              "Eliminar contacto",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextField(
              controller: nombreEliminarControl,
              decoration: const InputDecoration(
                labelText: 'Nombre a eliminar',
                prefixIcon: Icon(Icons.delete),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _eliminarDeRed,
              icon: const Icon(Icons.delete),
              label: const Text("Eliminar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
