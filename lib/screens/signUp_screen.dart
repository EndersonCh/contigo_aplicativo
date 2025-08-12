import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final supabase = Supabase.instance.client;
  final emailControl = TextEditingController();
  final claveControl = TextEditingController();

  bool _isLoading = false;
  String? _mensajeError;
  String? _mensajeExicto;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _mensajeError = null;
      _mensajeExicto = null;
    });

    try {
      final data = await supabase.auth.signUp(
        email: emailControl.text.trim(),
        password: claveControl.text.trim(),
      );

      if (data.user != null) {
        setState(() {
          _mensajeExicto = "Cuenta creada. Revisa tu correo para confirmar.";
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
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}
