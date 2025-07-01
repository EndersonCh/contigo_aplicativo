import 'package:flutter/material.dart';

class ImageInicio extends StatefulWidget {
  const ImageInicio({super.key});

  @override
  State<ImageInicio> createState() => _ImageInicioState();
}

class _ImageInicioState extends State<ImageInicio> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0, bottom: 16.0),
      child: Column(
        children: [Image.asset("assets/images/art/arte1.png", width: 500)],
      ),
    );
  }
}
