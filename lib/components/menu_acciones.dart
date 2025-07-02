import 'package:contigo_aplicativo/components/accion.dart';
import 'package:contigo_aplicativo/screens/encuentros_activos.dart';
import 'package:contigo_aplicativo/screens/inicio_screen.dart';
import 'package:contigo_aplicativo/screens/programar_encuentro.dart';
import 'package:flutter/material.dart';

class MenuAcciones extends StatefulWidget {
  const MenuAcciones({super.key});

  @override
  State<MenuAcciones> createState() => _MenuAccionesState();
}

class _MenuAccionesState extends State<MenuAcciones> {
  @override
  Widget build(BuildContext context) {
    return 
      Column(
        children: [
          Accion(
                imagenAccion: "assets/images/art/arte2.png", 
                titulo: "Programar un Encuentro", 
                textoContenido: "Añade direcciones, Nombres, números telefonicos y mas",
                destinoPantalla: ProgramarEncuentro()
          ),
          SizedBox(height: 15),
          Accion(
                imagenAccion: "assets/images/art/accion2.png", 
                titulo: "Encuentro Activos", 
                textoContenido: "Actualiza cualquier cambio de planes",
                destinoPantalla: EncuentrosActivos(),
          ),
          SizedBox(height: 15),
          Accion(
                imagenAccion: "assets/images/art/accion2.png", 
                titulo: "Mi Red de Apoyo", 
                textoContenido: "Gestiona, añade y conecta con los tuyos",
                destinoPantalla: InicioScreen()
          ),
        ],
      );
  }
}