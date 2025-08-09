import 'package:contigo_aplicativo/components/menu_acciones.dart';
import 'package:contigo_aplicativo/components/scroll_horizontal.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}


class _HomeState extends State<Home> {

    bool enviando = false;

  final supabase = Supabase.instance.client;

  Future<void> enviarMensajeSOS() async {
  setState(() => enviando = true);

  try {
    Position posicion = await obtenerUbicacion();

    final url = Uri.parse('https://wwizimtpwsbfrhneezqh.supabase.co/functions/v1/hyper-responder');

    final response = await supabase
        .functions
        .invoke('hyper-responder', body: {
          'latitud': posicion.latitude,
          'longitud': posicion.longitude,
        });

    if (response.status != 200) {
      throw Exception('Error desde función SOS: ${response.data}');
    }

    final data = response.data;
    final mensaje = data['mensaje'] ?? 'Mensaje recibido';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  } catch (e) {
    print('error de manifiesto ${e}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => enviando = false);
  }
}

  Future<Position> obtenerUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw Exception('El servicio de ubicación está desactivado');
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }


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
      body: Stack(
        children: [
          ListView(
            children:[
              SizedBox(height: 30),
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
                padding: const EdgeInsets.only(top:10),
                child: ScrollHorizontal(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20,top: 18),
                child: Text(
                  "Acciones: ",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: MenuAcciones()
              ),
              SizedBox(height: 100), // Espacio para el botón
            ]
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onDoubleTap: enviarMensajeSOS,
                child: Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: enviando 
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 40,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }
}