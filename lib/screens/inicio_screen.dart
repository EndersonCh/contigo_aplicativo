import 'package:contigo_aplicativo/components/cabecera_logo.dart';
import 'package:contigo_aplicativo/components/image_inicio.dart';
import 'package:flutter/material.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView (
      
      children: [
        Column(
          
          children: [
            CabeceraLogo(),
            ImageInicio(),

          ],
        )
      ],
    );
  }
}