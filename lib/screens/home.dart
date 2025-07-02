import 'package:contigo_aplicativo/components/scroll_horizontal.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top:20, left: 10),
          child: Image.asset(
            'assets/images/brand/logo1.png',
            height:25,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20,top: 20),
            child: IconButton(
              onPressed:(){
                //Accion para presionar el icono
              },
              icon: Icon(Icons.person_sharp),
              iconSize: 30,
              ),
          )
        ],
      ),
    body: ListView(
      children:[
        SizedBox(height: 40,),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            "Consejo del dia ",
            style: TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),),
        ),
        Padding(
          padding: const EdgeInsets.only(top:20),
          child: ScrollHorizontal(),
        ),
      ]
      ),
    );
  }
}