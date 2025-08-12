import 'package:contigo_aplicativo/components/accion.dart';
import 'package:contigo_aplicativo/screens/encuentros_activos.dart';
import 'package:contigo_aplicativo/screens/gestionRed_screen.dart';
import 'package:contigo_aplicativo/screens/inicio_screen.dart';
import 'package:contigo_aplicativo/screens/instrucciones_screen.dart'
    show InstruccionesScreen;
import 'package:contigo_aplicativo/screens/pantalla_entrada_encuentros.dart';
import 'package:contigo_aplicativo/screens/programar_encuentro.dart';
import 'package:contigo_aplicativo/screens/verRed_screen.dart';
import 'package:flutter/material.dart';

class MenuAcciones extends StatefulWidget {
  const MenuAcciones({super.key});

  @override
  State<MenuAcciones> createState() => _MenuAccionesState();
}

class _MenuAccionesState extends State<MenuAcciones> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Accion(
          imagenAccion: "assets/images/art/Mi_reds.png",
          titulo: "Mi red de Apoyo",
          textoContenido: "Acá estamos",
          destinoPantalla: VerredScreen(),
        ),
        SizedBox(height: 15),
        Accion(
          imagenAccion: "assets/images/art/gestion.png",
          titulo: "Administrar Red",
          textoContenido: "Agrega o elimina contactos",
          destinoPantalla: PantallaEntradaEncuentros(),
        ),
        SizedBox(height: 15),
        Accion(
          imagenAccion: "assets/images/art/SOSi.png",
          titulo: "S.O.S",
          textoContenido: "Descubre como funciona contigo",
          destinoPantalla: InstruccionesScreen(),
        ),
      ],
    );
  }
}
