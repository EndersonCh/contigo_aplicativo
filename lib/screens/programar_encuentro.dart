import 'package:contigo_aplicativo/components/formulario_tyc.dart';
import 'package:contigo_aplicativo/handlers/sqlite_handler.dart';
import 'package:flutter/material.dart';

class ProgramarEncuentro extends StatefulWidget {
  const ProgramarEncuentro({super.key});

  @override
  State<ProgramarEncuentro> createState() => _ProgramarEncuentroState();
}

class _ProgramarEncuentroState extends State<ProgramarEncuentro> {
  final TextEditingController ubicC= TextEditingController();
  final TextEditingController nombreC= TextEditingController();
  final TextEditingController perfilC= TextEditingController();
  final TextEditingController tlfC= TextEditingController();
  //guarda los datos en SQLite
  Future<void> guardarDatos() async{
    final handler= SqliteHandler();
    await handler.addData(
      ubicacion: ubicC.text,
      nombre: nombreC.text,
      perfil: perfilC.text,
      telefono: tlfC.text
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("¡Datos guardados correctamente!")),
    );
    ubicC.clear();
    nombreC.clear();
    perfilC.clear();
    tlfC.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Container(
          child: ListView(
            children: [
              SizedBox(height: 20,),
              Text(
                "Programar Encuentro",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
                Padding(
                  padding: const EdgeInsets.only(left:10,top: 4),
                  child: Text(
                    "Ten un encuentro seguro, completa los campos",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
              SizedBox(height: 15),
              Text(
                'Locación y hora',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20,),
              FormularioTyc(
                tituloC: 'Ubicación', 
                boxtex:'Local,Plaza ,sector ,calle',
                controller: ubicC,
                ),
              SizedBox(height:10,),
              Text(
                'Datos de la persona con la que te encontraras:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
                ),
              SizedBox(height: 5),
              FormularioTyc(
                tituloC: 'Nombre', 
                boxtex: 'Nombre',
                controller: nombreC,
                ),
              SizedBox(height: 2),
              FormularioTyc(
                tituloC: 'Perfil', 
                boxtex: 'Facebook/instagram',
                controller: perfilC,
                ),
              SizedBox(height: 2),
              FormularioTyc(
                tituloC: 'Telefono', 
                boxtex: 'tlf',
                controller: tlfC,
                ),
                SizedBox(height: 20,),
                Center(
                  child: ElevatedButton(
                    onPressed: guardarDatos, 
                    child: Text('Programar Encuentro')),
                )
            ],

          ),
        ),
      ),
    );
  }
}