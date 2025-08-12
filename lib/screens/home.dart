import 'dart:async';

import 'package:contigo_aplicativo/components/menu_acciones.dart';
import 'package:contigo_aplicativo/components/scroll_horizontal.dart';
import 'package:contigo_aplicativo/service/bluetooth_service.dart';
import 'package:contigo_aplicativo/service/foreground_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool enviando = false;
  bool servicioActivoPrimerPlano = false;
  bool contigoConectado = false;
  String estadoConexionBluetoo = "Inicializando...";
  String ultimoMensaje = "";
  List<String> listaMensajeEmergentes = [];

  final storage = FlutterSecureStorage();
  final supabase = Supabase.instance.client;
  final ESP32BluetoothService _bluetoothService = ESP32BluetoothService();

  @override
  void initState() {
    super.initState();
    inicializar();
  }

  Future<void> inicializar() async {
    try {
      await permisosNecesarios();

      bool iniciaPrimerPlano = await iniciarServicioPrimerPlano();
      if (!iniciaPrimerPlano) {
        return;
      }

      _bluetoothService.estadoConexiconESP32 = (blutooConectado) {
        if (mounted) {
          setState(() {
            contigoConectado = blutooConectado;
            estadoConexionBluetoo = blutooConectado
                ? "Contigo Conectado"
                : "Contigo Desconectado";
          });

          if (blutooConectado) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bluetooth conectado correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      };

      _bluetoothService.msjRecividosDelESP32 = (message) {
        if (mounted) {
          setState(() {
            ultimoMensaje = message;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor:
                  message.contains('SOS') || message.contains('EMERGENCIA')
                  ? Colors.red
                  : message.contains(' ')
                  ? Colors.green
                  : Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      };

      _bluetoothService.onError = (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error Bluetooth: $error'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      };
      bool bluetoothInitialized = await _bluetoothService
          .inicializarBluetooth();

      if (bluetoothInitialized) {
        await _bluetoothService.autoConectarAlESP32();
        await Future.delayed(Duration(seconds: 3));
      } else {
        setState(() {
          estadoConexionBluetoo = "Error Bluetooth";
        });
      }

      bool isRunning = await FlutterForegroundTask.isRunningService;
      if (mounted) {
        setState(() {
          servicioActivoPrimerPlano = isRunning;
          if (isRunning && estadoConexionBluetoo == "Inicializando...") {
            estadoConexionBluetoo = " Servicio activo - Buscando Contigo";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          estadoConexionBluetoo = "Error: $e";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inicializando servicios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> permisosNecesarios() async {
    try {
      await Permission.location.request();
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();

      if (!await FlutterForegroundTask.canDrawOverlays) {
        bool userAccepted = await instruccionesDePermisos();

        if (userAccepted) {
          await FlutterForegroundTask.openSystemAlertWindowSettings();
          await Future.delayed(Duration(seconds: 2));

          if (!await FlutterForegroundTask.canDrawOverlays) {
            throw Exception('Permiso de superposicion requerido');
          }
        } else {
          throw Exception('Permiso de superposicion denegado por el usuario');
        }
      }
    } catch (e) {
      throw e;
    }
  }

  Future<bool> instruccionesDePermisos() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Permiso Requerido'),
              content: Text(
                'Para que Contigo funcione en segundo plano, necesita permiso para '
                'mostrar contenido sobre otras aplicaciones.\n\n'
                'Esto es necesario para:\n'
                '• Mantener la protección activa\n'
                '• Recibir alertas SOS del Contigo\n'
                '• Funcionar aunque cambies de app\n\n'
                '¿Deseas continuar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Continuar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> iniciarServicioPrimerPlano() async {
    try {
      await ForegroundService.initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> alternarServicioSOS() async {
    try {
      if (servicioActivoPrimerPlano) {
        print('Deteniendo servicio...');
        await ForegroundService.stopService();
        await _bluetoothService.disconnectarEsp32();

        if (mounted) {
          setState(() {
            servicioActivoPrimerPlano = false;
            contigoConectado = false;
            estadoConexionBluetoo = " Servicio detenido";
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Servicio de proteccion desactivado'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        bool canStart = await verificarPermisos();
        if (!canStart) {
          return;
        }

        if (mounted) {
          setState(() {
            estadoConexionBluetoo = " Iniciando servicio...";
          });
        }

        bool started = await ForegroundService.startService();

        if (started) {
          if (mounted) {
            setState(() {
              servicioActivoPrimerPlano = true;
              estadoConexionBluetoo =
                  " Servicio activo - Iniciando Bluetooth...";
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servicio de proteccion activado'),
              backgroundColor: Colors.green,
            ),
          );
          bool bluetoothReady = await _bluetoothService.inicializarBluetooth();

          if (bluetoothReady) {
            setState(() {
              estadoConexionBluetoo = "Buscando Bluetooth Contigo...";
            });
            await _bluetoothService.autoConectarAlESP32();
          } else {
            setState(() {
              estadoConexionBluetoo = "Error Bluetooth";
            });
          }
        } else {
          if (mounted) {
            setState(() {
              estadoConexionBluetoo = " Error al iniciar";
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Error al activar el servicio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          estadoConexionBluetoo = " Error: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> verificarPermisos() async {
    try {
      if (!await FlutterForegroundTask.canDrawOverlays) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Se requiere permiso de superposicion'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () async {
                await permisosNecesarios();
              },
            ),
          ),
        );
        return false;
      }

      bool bluetoothEnabled = await Permission.bluetooth.isGranted;
      if (!bluetoothEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Se requiere permiso de Bluetooth'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      return true;
    } catch (e) {
      print(' Error verificando permisos: $e');
      return false;
    }
  }

  Future<void> reiniciarBusquedaBluetoo() async {
    await _bluetoothService.autoConectarAlESP32();
  }

  Future<void> monitorBluetoo() async {
    String contigoC = '';
    if (contigoConectado) {
      contigoC = 'Bluetooth Contigo Esta conectado';
    } else {
      contigoC = 'Bluetooth Contigo NO Esta conectado';
    }

    String debugInfo =
        '''
    Estado actual:
• $contigoC
• Estado: $estadoConexionBluetoo
• Ultimo mensaje: $ultimoMensaje

 Para solucionar problemas:
1. Verifica que tu dispositivo Contigo este encendido
2. Verifica que no este conectado a otro dispositivo
3. Prueba reiniciar el Bluetooth del teléfono
        ''';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informacion de dispositivo Contigo'),
          content: Text(debugInfo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> enviarMensajeSOS() async {
    setState(() => enviando = true);
    String? userId = await storage.read(key: 'user_id');

    if (userId != null && userId.isNotEmpty) {
      try {
        Position posicion = await obtenerUbicacion();

        final response = await supabase.functions.invoke(
          'hyper-responder',
          body: {
            'latitud': posicion.latitude,
            'longitud': posicion.longitude,
            'id': userId,
          },
        );

        if (response.status != 200) {
          throw Exception('Error desde función SOS: ${response.data}');
        }

        final data = response.data;
        final mensaje = data['mensaje'] ?? 'Mensaje recibido';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensaje)));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => enviando = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error! Accede a tu cuenta y a tu red de apoyo'),
        ),
      );
    }
  }

  Future<Position> obtenerUbicacion() async {
    bool servicioActivoPrimerPlano =
        await Geolocator.isLocationServiceEnabled();
    if (!servicioActivoPrimerPlano) {
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
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 20, left: 10),
          child: Image.asset('assets/images/brand/logo1.png', height: 25),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.person_sharp),
              iconSize: 30,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: contigoConectado
                      ? Colors.green[50]
                      : servicioActivoPrimerPlano
                      ? Colors.yellow[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: contigoConectado
                        ? Colors.green
                        : servicioActivoPrimerPlano
                        ? Colors.orange
                        : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          contigoConectado
                              ? Icons.bluetooth_connected
                              : servicioActivoPrimerPlano
                              ? Icons.bluetooth_searching
                              : Icons.bluetooth_disabled,
                          color: contigoConectado
                              ? Colors.green
                              : servicioActivoPrimerPlano
                              ? Colors.orange
                              : Colors.red,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                servicioActivoPrimerPlano
                                    ? "Proteccion Activa"
                                    : "Protección Inactiva",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: contigoConectado
                                      ? Colors.green[700]
                                      : servicioActivoPrimerPlano
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                                ),
                              ),
                              Text(
                                estadoConexionBluetoo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (ultimoMensaje.isNotEmpty)
                                Text(
                                  "Último: $ultimoMensaje",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          value: servicioActivoPrimerPlano,
                          onChanged: (value) => alternarServicioSOS(),
                          activeColor: contigoConectado
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),

                    if (servicioActivoPrimerPlano) ...[
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: reiniciarBusquedaBluetoo,
                            icon: Icon(Icons.bluetooth_searching, size: 16),
                            label: Text(
                              'Reintentar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: Size(100, 32),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: monitorBluetoo,
                            icon: Icon(Icons.info, size: 16),
                            label: Text(
                              'Monitor',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              minimumSize: Size(80, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  "Consejo del dia ",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ScrollHorizontal(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 18),
                child: Text(
                  "Acciones: ",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: MenuAcciones(),
              ),
              SizedBox(height: 100),
            ],
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Icon(Icons.emergency, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
