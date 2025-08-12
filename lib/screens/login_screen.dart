import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;
  final emailControl = TextEditingController();
  final claveControl = TextEditingController();
  bool _isLoading = false;
  String? _mensajeError;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _mensajeError = null;
    });

    try {
      final data = await supabase.auth.signInWithPassword(
        email: emailControl.text.trim(),
        password: claveControl.text.trim(),
      );

      if (data.session == null) {
        setState(() {
          _mensajeError = "Datos invalidos";
        });
      }
    } catch (e) {
      setState(() {
        _mensajeError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
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
            TextField(
              controller: emailControl,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: claveControl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            if (_mensajeError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Iniciar sesión"),
            ),
          ],
        ),
      ),
    );
  }
}
