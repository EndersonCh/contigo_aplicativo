import 'package:contigo_aplicativo/components/CabeceraLogo.dart';
import 'package:contigo_aplicativo/components/ImageInicio.dart';
import 'package:flutter/material.dart';

class Inicioscreen extends StatefulWidget {
  const Inicioscreen({super.key});

  @override
  State<Inicioscreen> createState() => _InicioscreenState();
}

class _InicioscreenState extends State<Inicioscreen> {
  @override
  Widget build(BuildContext context) {
    return ListView (
      
      children: [
        Column(
          
          children: [
            Cabeceralogo(),
            Imageinicio(),

          ],
        )
      ],
    );
  }
}