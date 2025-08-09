import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrarUser extends StatefulWidget {
  const RegistrarUser({super.key});

  @override
  State<RegistrarUser> createState() => _RegistrarUserState();
}
class _RegistrarUserState extends State<RegistrarUser> {
  final emailControl=TextEditingController();
  final claveControl =TextEditingController();
  final nombreControl=TextEditingController();
  final supabase =Supabase.instance.client;
  String msjError='';

   void registrarUser() async {
    final email = emailControl.text.trim();
    final password = claveControl.text.trim();
    final nombre = nombreControl.text.trim();

    if (email.isEmpty || password.isEmpty || nombre.isEmpty) {
      setState(() {
        msjError = 'Por favor completa todos los campos.';
      });
      return;
    }

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
        },
      );

      final user = response.user;
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Revisa tu correo y confírmalo para completar el registro!')),
        );
      }

    } catch (e) {
      print("Error en registro: $e");
      setState(() {
        msjError = 'Ocurrió un error al registrar: $e';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}