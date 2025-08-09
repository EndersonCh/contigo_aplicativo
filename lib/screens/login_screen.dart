import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Function(String,String) login;
  const LoginScreen({required this.login,super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailControl =TextEditingController();
  final TextEditingController claveControl =TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email'),
        TextField(
          controller: emailControl,
          decoration: InputDecoration(
            hintText: 'ejemplo@gmail.com',
          ),
        ),
        SizedBox(height: 10,),
        Text('Clave'),
        TextField(
          controller: claveControl,
          obscureText: true,
        ),
        SizedBox(height: 20,),
        Center(
          child: ElevatedButton(
            onPressed:(){
              final email=emailControl.text.trim();
              final clave =claveControl.text.trim();
              widget.login(email,clave);
            },
            child: Text('Iniciar Sesión')),
        )
      ],
    );
  }
}