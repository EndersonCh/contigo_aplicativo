import 'package:contigo_aplicativo/screens/gestionRed_screen.dart';
import 'package:contigo_aplicativo/screens/login_screen.dart';
import 'package:contigo_aplicativo/screens/registrar_user.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PantallaEntradaEncuentros extends StatefulWidget {
  const PantallaEntradaEncuentros({super.key});

  @override
  State<PantallaEntradaEncuentros> createState() =>
      _PantallaEntradaEncuentrosState();
}

class _PantallaEntradaEncuentrosState extends State<PantallaEntradaEncuentros> {
  bool mostrarReg = false;
  final supabase = Supabase.instance.client;
  final storage = FlutterSecureStorage();
  Future<void> hacerLogin(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final userId = response.user!.id;
        await storage.write(key: 'user_id', value: userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GestionredScreen()),
        );
      }
      if (response.user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(height: 40),

                        SizedBox(height: 18),
                        mostrarReg
                            ? RegistrarUser()
                            : LoginScreen(onLogin: hacerLogin),

                        Spacer(),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 80.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                mostrarReg = !mostrarReg;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 22.0,
                              ),
                              child: Text(
                                mostrarReg
                                    ? '¿Ya tienes cuenta? Inicia sesión'
                                    : '¿No tienes cuenta? Regístrate',
                                style: TextStyle(
                                  color: Colors.teal,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
