import 'package:flutter/material.dart';

class Accion extends StatefulWidget {
  final String imagenAccion;
  final String titulo;
  final String textoContenido;
  final Widget destinoPantalla;
  const Accion({
    required this.imagenAccion
,
    required this.titulo,
    required this.textoContenido,
    required this.destinoPantalla,
    super.key,
    });

  @override
  State<Accion> createState() => _AccionState();
}

class _AccionState extends State<Accion> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10,right: 10),
      child: GestureDetector(
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=>widget.destinoPantalla)
            );
        },
        child: Container(
          decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 236, 243),
          borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  widget.imagenAccion,
                  width: 140,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          widget.titulo,
                          softWrap: true,
                          overflow: TextOverflow.clip,
                          maxLines: 2,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          )
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:10,left: 5),
                        child: Text(
                          widget.textoContenido,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontSize: 13,
                          
                          )
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}