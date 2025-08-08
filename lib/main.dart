import 'package:contigo_aplicativo/screens/home.dart';
import 'package:contigo_aplicativo/screens/inicio_screen.dart';
//import 'package:contigo_aplicativo/screens/inicio_screen.dart';
import 'package:flutter/material.dart';

void main() {
  //para la base de datos 
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body:InicioScreen(),
        
      ),
    );
  }
}
