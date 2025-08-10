import 'package:contigo_aplicativo/components/menu_acciones.dart';
import 'package:contigo_aplicativo/components/scroll_horizontal.dart';
import 'package:contigo_aplicativo/service/bluetooth_service.dart';
import 'package:contigo_aplicativo/service/foreground_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool enviando = false;
  bool servicioActivo = false;
  bool esp32Conectado = false;
  String estadoConexion = "Inicializando...";
  String ultimoMensaje = "";
  List<String> logMessages = []; // Para mostrar el proceso de conexión

  final supabase = Supabase.instance.client;
  final ESP32BluetoothService _bluetoothService = ESP32BluetoothService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Inicializar servicios al cargar la pantalla
  Future<void> _initializeServices() async {
    try {
      print('🚀 Inicializando servicios...');
      _addLogMessage('🚀 Inicializando servicios...');
      
      // Solicitar permisos necesarios PRIMERO
      await _requestPermissions();
      
      // Inicializar servicio en primer plano con verificación
      bool initialized = await _initializeForegroundService();
      if (!initialized) {
        print('❌ Error inicializando servicio en primer plano');
        _addLogMessage('❌ Error inicializando servicio en primer plano');
        return;
      }
      
      // ✅ AQUÍ ESTABA EL PROBLEMA - Configurar callbacks del servicio Bluetooth
      _bluetoothService.onConnectionStatusChanged = (isConnected) {
        if (mounted) {
          setState(() {
            esp32Conectado = isConnected;
            estadoConexion = isConnected ? "✅ ESP32 Conectado" : "❌ ESP32 Desconectado";
          });
          
          if (isConnected) {
            _addLogMessage('✅ Bluetooth conectado correctamente');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bluetooth conectado correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      };

      _bluetoothService.onMessageReceived = (message) {
        if (mounted) {
          setState(() {
            ultimoMensaje = message;
          });
          
          _addLogMessage(message);
          
          // Mostrar notificación en la app
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: message.contains('SOS') || message.contains('EMERGENCIA') 
                  ? Colors.red 
                  : message.contains('✅') 
                      ? Colors.green 
                      : Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      };

      _bluetoothService.onError = (error) {
        if (mounted) {
          _addLogMessage('❌ Error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error Bluetooth: $error'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      };

      // ✅ INICIALIZAR BLUETOOTH SERVICE
      _addLogMessage('🔵 Inicializando Bluetooth...');
      bool bluetoothInitialized = await _bluetoothService.initialize();
      
      if (bluetoothInitialized) {
        _addLogMessage('✅ Bluetooth inicializado');
        
        // ✅ AQUÍ ESTABA EL PROBLEMA PRINCIPAL - INICIAR LA BÚSQUEDA DEL ESP32
        _addLogMessage('🔍 Iniciando búsqueda de ESP32...');
        await _bluetoothService.startAutoConnect();
        
      } else {
        _addLogMessage('❌ Error al inicializar Bluetooth');
        setState(() {
          estadoConexion = "❌ Error Bluetooth";
        });
      }

      // Verificar si el servicio ya está activo
      bool isRunning = await FlutterForegroundTask.isRunningService;
      if (mounted) {
        setState(() {
          servicioActivo = isRunning;
          if (isRunning && estadoConexion == "Inicializando...") {
            estadoConexion = "🟡 Servicio activo - Buscando ESP32";
          }
        });
      }

      print('✅ Servicios inicializados correctamente');
      _addLogMessage('✅ Servicios inicializados correctamente');
      
    } catch (e) {
      print('❌ Error inicializando servicios: $e');
      _addLogMessage('❌ Error inicializando servicios: $e');
      
      if (mounted) {
        setState(() {
          estadoConexion = "❌ Error: $e";
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

  /// Agregar mensaje al log visible
  void _addLogMessage(String message) {
    if (mounted) {
      setState(() {
        logMessages.add("${DateTime.now().toString().substring(11, 19)} - $message");
        // Mantener solo los últimos 10 mensajes
        if (logMessages.length > 10) {
          logMessages.removeAt(0);
        }
      });
    }
  }

  /// Solicitar todos los permisos necesarios
  Future<void> _requestPermissions() async {
    try {
      _addLogMessage('🔐 Solicitando permisos...');
      
      // Permisos básicos
      await Permission.location.request();
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      
      // Verificar si puede dibujar sobre otras apps (CRÍTICO)
      if (!await FlutterForegroundTask.canDrawOverlays) {
        print('⚠️ Solicitando permiso para dibujar sobre otras apps...');
        
        // Mostrar diálogo explicativo ANTES de abrir configuración
        bool userAccepted = await _showOverlayPermissionDialog();
        
        if (userAccepted) {
          await FlutterForegroundTask.openSystemAlertWindowSettings();
          
          // Esperar un momento para que el usuario configure el permiso
          await Future.delayed(Duration(seconds: 2));
          
          // Verificar si se otorgó el permiso
          if (!await FlutterForegroundTask.canDrawOverlays) {
            throw Exception('Permiso de superposición requerido');
          }
        } else {
          throw Exception('Permiso de superposición denegado por el usuario');
        }
      }

      // Verificar optimización de batería
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        print('⚠️ Solicitando ignorar optimización de batería...');
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      
      print('✅ Permisos solicitados correctamente');
      _addLogMessage('✅ Permisos configurados');
      
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      _addLogMessage('❌ Error en permisos: $e');
      throw e;
    }
  }

  /// Mostrar diálogo explicativo antes de solicitar permiso de superposición
  Future<bool> _showOverlayPermissionDialog() async {
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
            '• Recibir alertas SOS del ESP32\n'
            '• Funcionar aunque cambies de app\n\n'
            '¿Deseas continuar?'
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
    ) ?? false;
  }

  /// Inicializar servicio en primer plano con verificación
  Future<bool> _initializeForegroundService() async {
    try {
      print('🔧 Inicializando servicio en primer plano...');
      _addLogMessage('🔧 Configurando servicio...');
      
      // Inicializar la configuración del servicio
      await ForegroundService.initialize();
      
      print('✅ Servicio en primer plano inicializado');
      _addLogMessage('✅ Servicio configurado');
      return true;
      
    } catch (e) {
      print('❌ Error inicializando servicio en primer plano: $e');
      _addLogMessage('❌ Error configurando servicio: $e');
      return false;
    }
  }

  /// Alternar el servicio de protección (CORREGIDO)
  Future<void> _toggleProtectionService() async {
    try {
      if (servicioActivo) {
        print('🛑 Deteniendo servicio...');
        _addLogMessage('🛑 Deteniendo servicio...');
        
        await ForegroundService.stopService();
        await _bluetoothService.disconnect();
        
        if (mounted) {
          setState(() {
            servicioActivo = false;
            esp32Conectado = false;
            estadoConexion = "🔴 Servicio detenido";
          });
        }
        
        _addLogMessage('🔴 Servicio detenido');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Servicio de protección desactivado'),
            backgroundColor: Colors.orange,
          ),
        );
        
      } else {
        print('🚀 Iniciando servicio...');
        _addLogMessage('🚀 Iniciando servicio...');
        
        // Verificar permisos antes de iniciar
        bool canStart = await _verifyPermissionsBeforeStart();
        if (!canStart) {
          return;
        }
        
        if (mounted) {
          setState(() {
            estadoConexion = "🟡 Iniciando servicio...";
          });
        }
        
        bool started = await ForegroundService.startService();
        
        if (started) {
          if (mounted) {
            setState(() {
              servicioActivo = true;
              estadoConexion = "🟡 Servicio activo - Iniciando Bluetooth...";
            });
          }
          
          _addLogMessage('✅ Servicio activado');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Servicio de protección activado'),
              backgroundColor: Colors.green,
            ),
          );
          
          // ✅ INICIALIZAR Y CONECTAR BLUETOOTH DESPUÉS DE ACTIVAR EL SERVICIO
          _addLogMessage('🔵 Inicializando Bluetooth...');
          bool bluetoothReady = await _bluetoothService.initialize();
          
          if (bluetoothReady) {
            _addLogMessage('🔍 Buscando ESP32...');
            setState(() {
              estadoConexion = "🔍 Buscando ESP32...";
            });
            
            // ✅ INICIAR LA BÚSQUEDA DEL ESP32
            await _bluetoothService.startAutoConnect();
          } else {
            _addLogMessage('❌ Error al inicializar Bluetooth');
            setState(() {
              estadoConexion = "❌ Error Bluetooth";
            });
          }
          
          print('✅ Servicio iniciado correctamente');
          
        } else {
          if (mounted) {
            setState(() {
              estadoConexion = "❌ Error al iniciar";
            });
          }
          
          _addLogMessage('❌ Error al iniciar servicio');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al activar el servicio'),
              backgroundColor: Colors.red,
            ),
          );
          
          print('❌ No se pudo iniciar el servicio');
        }
      }
      
    } catch (e) {
      print('❌ Error en _toggleProtectionService: $e');
      _addLogMessage('❌ Error: $e');
      
      if (mounted) {
        setState(() {
          estadoConexion = "❌ Error: $e";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Verificar permisos antes de iniciar servicio
  Future<bool> _verifyPermissionsBeforeStart() async {
    try {
      // Verificar permiso de superposición
      if (!await FlutterForegroundTask.canDrawOverlays) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Se requiere permiso de superposición'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () async {
                await _requestPermissions();
              },
            ),
          ),
        );
        return false;
      }
      
      // Verificar Bluetooth
      bool bluetoothEnabled = await Permission.bluetooth.isGranted;
      if (!bluetoothEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Se requiere permiso de Bluetooth'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      return true;
      
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }

  /// Solicitar todos los permisos necesarios
  Future<void> requerimientos() async {
    try {
      _addLogMessage('🔐 Solicitando permisos...');
      
      // Permisos básicos
      await Permission.location.request();
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      
      // Verificar si puede dibujar sobre otras apps (CRÍTICO)
      if (!await FlutterForegroundTask.canDrawOverlays) {
        print('⚠️ Solicitando permiso para dibujar sobre otras apps...');
        
        // Mostrar diálogo explicativo ANTES de abrir configuración
        bool userAccepted = await _showOverlayPermissionDialog();
        
        if (userAccepted) {
          await FlutterForegroundTask.openSystemAlertWindowSettings();
          
          // Esperar un momento para que el usuario configure el permiso
          await Future.delayed(Duration(seconds: 2));
          
          // Verificar si se otorgó el permiso
          if (!await FlutterForegroundTask.canDrawOverlays) {
            throw Exception('Permiso de superposición requerido');
          }
        } else {
          throw Exception('Permiso de superposición denegado por el usuario');
        }
      }

      // Verificar optimización de batería
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        print('⚠️ Solicitando ignorar optimización de batería...');
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      
      print('✅ Permisos solicitados correctamente');
      _addLogMessage('✅ Permisos configurados');
      
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      _addLogMessage('❌ Error en permisos: $e');
      throw e;
    }
  }

  /// Mostrar diálogo explicativo antes de solicitar permiso de superposición
  Future<bool> mostrarDialogo() async {
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
            '• Recibir alertas SOS del ESP32\n'
            '• Funcionar aunque cambies de app\n\n'
            '¿Deseas continuar?'
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
    ) ?? false;
  }

  /// Inicializar servicio en primer plano con verificación
  Future<bool> inicializarServicio() async {
    try {
      print('🔧 Inicializando servicio en primer plano...');
      _addLogMessage('🔧 Configurando servicio...');
      
      // Inicializar la configuración del servicio
      await ForegroundService.initialize();
      
      print('✅ Servicio en primer plano inicializado');
      _addLogMessage('✅ Servicio configurado');
      return true;
      
    } catch (e) {
      print('❌ Error inicializando servicio en primer plano: $e');
      _addLogMessage('❌ Error configurando servicio: $e');
      return false;
    }
  }

  /// 🆕 Escanear manualmente (reiniciar búsqueda)
  Future<void> _scanAllDevices() async {
    _addLogMessage('🔍 Reintentando búsqueda de ESP32...');
    await _bluetoothService.startAutoConnect();
  }

  /// 🆕 Mostrar información de debugging
  Future<void> _showDebugInfo() async {
    String debugInfo = '''
Estado actual:
• Servicio activo: $servicioActivo
• ESP32 conectado: $esp32Conectado
• Estado: $estadoConexion
• Último mensaje: $ultimoMensaje

Para solucionar problemas:
1. Verifica que el ESP32 esté encendido
2. Asegúrate que esté transmitiendo como "CONTIGO-SOS"
3. Verifica que no esté conectado a otro dispositivo
4. Prueba reiniciar el Bluetooth del teléfono
''';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Información de Debug'),
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



  /// Función original de envío manual de SOS
  Future<void> enviarMensajeSOS() async {
    setState(() => enviando = true);

    try {
      Position posicion = await obtenerUbicacion();

      final response = await supabase.functions.invoke('hyper-responder', body: {
        'latitud': posicion.latitude,
        'longitud': posicion.longitude,
        // 'origen': 'manual', // Identificar que fue manual
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
          child: Image.asset(
            'assets/images/brand/logo1.png',
            height: 25,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: IconButton(
              onPressed: () {
                // Acción para presionar el icono
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
            children: [
              SizedBox(height: 20),
              
              // Tarjeta de estado del servicio
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esp32Conectado 
                      ? Colors.green[50] 
                      : servicioActivo 
                          ? Colors.yellow[50] 
                          : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esp32Conectado 
                        ? Colors.green 
                        : servicioActivo 
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
                          esp32Conectado 
                              ? Icons.bluetooth_connected
                              : servicioActivo 
                                  ? Icons.bluetooth_searching
                                  : Icons.bluetooth_disabled,
                          color: esp32Conectado 
                              ? Colors.green 
                              : servicioActivo 
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
                                servicioActivo ? "Protección Activa" : "Protección Inactiva",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: esp32Conectado 
                                      ? Colors.green[700] 
                                      : servicioActivo 
                                          ? Colors.orange[700] 
                                          : Colors.red[700],
                                ),
                              ),
                              Text(
                                estadoConexion,
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
                          value: servicioActivo,
                          onChanged: (value) => _toggleProtectionService(),
                          activeColor: esp32Conectado ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    
                    // 🆕 Botones de debug
                    if (servicioActivo) ...[
                      SizedBox(height: 12),
                                              Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _scanAllDevices,
                            icon: Icon(Icons.bluetooth_searching, size: 16),
                            label: Text('Reintentar', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: Size(100, 32),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showDebugInfo,
                            icon: Icon(Icons.info, size: 16),
                            label: Text('Debug', style: TextStyle(fontSize: 12)),
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

              // 🆕 Log de mensajes visible
              if (logMessages.isNotEmpty) ...[
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.terminal, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text(
                            'Log de Actividad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                logMessages.clear();
                              });
                            },
                            icon: Icon(Icons.clear, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          itemCount: logMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                logMessages[index],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.grey[700],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
              SizedBox(height: 100), // Espacio para el botón
            ],
          ),
          
          // Botón SOS Manual
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