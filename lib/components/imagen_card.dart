import 'package:flutter/material.dart';

class ImagenCard extends StatefulWidget {
  final String imagenDirect;
  final String texto; 
  const ImagenCard({
    super.key,
    required this.imagenDirect,
    required this.texto,
    });

  @override
  State<ImagenCard> createState() => _ImagenCardState();
}

class _ImagenCardState extends State<ImagenCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 1),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              widget.imagenDirect,
              width: 350,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 10,
            bottom: 60,
            right: 16,
            child: Text(
              softWrap: true,
              overflow: TextOverflow.clip,
              maxLines: 4,
              widget.texto,
              style: TextStyle(
                color: const Color.fromARGB(255, 243, 242, 245),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black26,
                    offset: Offset(2, 2),
                  )
                ]
              ),
          ))
        ],
      ),
    );
  }
}