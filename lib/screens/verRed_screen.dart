import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerredScreen extends StatefulWidget {
  const VerredScreen({super.key});

  @override
  State<VerredScreen> createState() => _VerredScreenState();
}

class _VerredScreenState extends State<VerredScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<dynamic> _listaContactos = [];

  @override
  void initState() {
    super.initState();
    _cargarContactos();
  }

  Future<void> _cargarContactos() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await supabase
          .from("contactos_sos")
          .select()
          .eq("user_id", userId);

      setState(() => _listaContactos = data);
    } catch (e) {
      debugPrint("Error cargando contactos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mis Contactos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 125, 37, 213),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listaContactos.isEmpty
          ? const Center(child: Text("No hay contactos agregados"))
          : ListView.builder(
              itemCount: _listaContactos.length,
              itemBuilder: (context, i) {
                final contacto = _listaContactos[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 125, 37, 213),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(contacto['nombre'] ?? 'Sin nombre'),
                  subtitle: Text(contacto['telefono'] ?? 'Sin teléfono'),
                );
              },
            ),
    );
  }
}
