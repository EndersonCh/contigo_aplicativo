import 'package:flutter/material.dart';

class Imageinicio extends StatefulWidget {
  const Imageinicio({super.key});

  @override
  State<Imageinicio> createState() => _ImageinicioState();
}

class _ImageinicioState extends State<Imageinicio> {
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
