import 'package:flutter/material.dart';

class FormularioTyc extends StatefulWidget {
  final String tituloC;
  final String boxtex;
  final TextEditingController controller;

  const FormularioTyc({
    required this.tituloC,
    required this.boxtex,
    required this.controller,
    super.key});

  @override
  State<FormularioTyc> createState() => _FormularioTycState();
}

class _FormularioTycState extends State<FormularioTyc> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.tituloC,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextField(
              controller: widget.controller,
              maxLines: 1,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: widget.boxtex,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20)
                )
                ),),
          ),
      ],
    );
  }
}