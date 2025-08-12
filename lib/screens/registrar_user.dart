import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrarUser extends StatefulWidget {
  const RegistrarUser({super.key});

  @override
  State<RegistrarUser> createState() => _RegistrarUserState();
}

class _RegistrarUserState extends State<RegistrarUser> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  String msjError = '';


  void registrarUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    
    setState(() {
      msjError = '';
    });

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
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
  return Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
        ),
        SizedBox(height: 10),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: registrarUser,
          child: Text(
            'Registrar',
            style: TextStyle(
              color: Color.fromRGBO(108, 54, 215, 0.988),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (msjError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(msjError, style: TextStyle(color: Colors.red)),
          ),
      ],
    ),
  );
}
}