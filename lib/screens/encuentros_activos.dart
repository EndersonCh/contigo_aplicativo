import 'package:contigo_aplicativo/handlers/sqlite_handler.dart';
import 'package:flutter/material.dart';

class EncuentrosActivos extends StatefulWidget {
  const EncuentrosActivos({super.key});

  @override
  State<EncuentrosActivos> createState() => _EncuentrosActivosState();
}

class _EncuentrosActivosState extends State<EncuentrosActivos> {
  List<Map<String, dynamic>> listaEncuentros=[];
  @override
  void initState(){
    super.initState();
    cargarEncuentros();
  }

  Future<void> cargarEncuentros() async{
    final handler =SqliteHandler();
    final datos =await handler.obtenerDatos();
    setState(() {
      listaEncuentros= datos;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (listaEncuentros.isEmpty){
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(left: 20,top: 20),
          child: Text(
              "No hay encuentro guardados, Crea uno en Programar un Encuentro",
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            )
          
        ),
      );
    }else{
    return Scaffold(
      body: ListView.builder(//funciona como un for que recorre los registros
        itemCount: listaEncuentros.length,
        itemBuilder: (context,index){
          final encu=listaEncuentros[index];
          return Column(
            children: [
              Text("Nombre: ${encu['nombre']?? ''}"),
              Text("Ubicacion: ${encu['ubicacion']?? ''}"),
              Text("Perfil: ${encu['perfil']?? ''}"),
              Text("Telefono: ${encu['telefono']?? ''}"),
              const Divider()// linea separadora entre registros
            ],
          );
        }
        
      ),
    );
    }
   }
}