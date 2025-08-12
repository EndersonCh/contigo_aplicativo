import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ESP32BluetoothService {
  static final ESP32BluetoothService _instance =
      ESP32BluetoothService._internal();
  factory ESP32BluetoothService() => _instance;
  ESP32BluetoothService._internal();

  final supabase = Supabase.instance.client;

  BluetoothDevice? _dispositivoConectado;
  BluetoothCharacteristic? _canalDeMensajes;
  StreamSubscription<List<int>>? _escuchadorDeMensaje;
  StreamSubscription<List<ScanResult>>? _escuchadorDeDispositivo;
  StreamSubscription<BluetoothConnectionState>? _escuchadorDeCambConexion;
  bool _bandDeEscaneo = false;
  bool _bandDeConexion = false;
  bool _bandDeReconexion = false;
  Timer? _temporizadorReconexion;
  Timer? _temporizadorEscaneo;

  static const String ESP32_NAME = "CONTIGO-SOS";
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Callbacks para notificar eventos
  Function(String)? msjRecividosDelESP32;
  Function(bool)? estadoConexiconESP32;
  Function(String)? onError;

  bool get estaConectado => _bandDeConexion;
  BluetoothDevice? get connectedDevice => _dispositivoConectado;

  Future<bool> inicializarBluetooth() async {
    try {
      await _cleanup();

      if (!await FlutterBluePlus.isSupported) {
        String errorMsg = "Bluetooth no es soportado en este dispositivo";
        onError?.call(errorMsg);
        msjRecividosDelESP32?.call(" $errorMsg");
        return false;
      }

      bool permissionsGranted = await permisosDBuetooth();
      if (!permissionsGranted) {
        String errorMsg = "Permisos de Bluetooth denegados";
        onError?.call(errorMsg);
        msjRecividosDelESP32?.call(" $errorMsg");
        return false;
      }

      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        String errorMsg = "Bluetooth está desactivado. Por favor actívalo";
        onError?.call(errorMsg);
        msjRecividosDelESP32?.call(" $errorMsg");
        return false;
      }
      msjRecividosDelESP32?.call("Bluetooth inicializado correctamente");
      return true;
    } catch (e) {
      String errorMsg = "Error al inicializar Bluetooth: $e";
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call("$errorMsg");
      return false;
    }
  }

  Future<bool> permisosDBuetooth() async {
    try {
      Map<Permission, PermissionStatus> permissions = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = true;
      permissions.forEach((permission, status) {
        if (status.isDenied || status.isPermanentlyDenied) {
          print(" Permiso denegado: $permission");
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      print(" Error solicitando permisos: $e");
      return false;
    }
  }

  Future<void> autoConectarAlESP32() async {
    if (_bandDeEscaneo) {
      print("Ya hay un escaneo en progreso");
      return;
    }

    try {
      _bandDeEscaneo = true;
      print("Iniciando búsqueda del Bluetooth...");
      msjRecividosDelESP32?.call(" Buscando dispositivo Bluetooth...");
      _temporizadorEscaneo?.cancel();
      _temporizadorEscaneo = Timer(Duration(seconds: 10), () async {
        if (_bandDeEscaneo) {
          await _stopScan();
          if (!_bandDeConexion && !_bandDeReconexion) {
            msjRecividosDelESP32?.call(
              " Tiempo de busqueda agotado. Reintentando...",
            );
            _reintentoDeConexion();
          }
        }
      });
      await _escuchadorDeDispositivo?.cancel();
      _escuchadorDeDispositivo = FlutterBluePlus.scanResults.listen((
        results,
      ) async {
        for (ScanResult result in results) {
          String deviceName = result.device.platformName;
          String deviceId = result.device.remoteId.toString();

          print(" Dispositivo encontrado: '$deviceName' (ID: $deviceId)");

          if (_isTargetDevice(deviceName)) {
            print(" ESP32 objetivo encontrado: $deviceName");
            msjRecividosDelESP32?.call(
              "Dispositivo Contigo encontrado: $deviceName",
            );
            await _stopScan();
            await _connectToDevice(result.device);
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      print(" Escaneo iniciado correctamente");
    } catch (e) {
      String errorMsg = "Error en escaneo: $e";
      print(" $errorMsg");
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call(" $errorMsg");
      _bandDeEscaneo = false;
    }
  }

  bool _isTargetDevice(String deviceName) {
    if (deviceName.isEmpty) return false;
    String upperName = deviceName.toUpperCase();

    if (upperName == ESP32_NAME.toUpperCase()) {
      return true;
    }

    return false;
  }

  Future<void> _stopScan() async {
    try {
      if (_bandDeEscaneo) {
        await FlutterBluePlus.stopScan();
        _temporizadorEscaneo?.cancel();
        await _escuchadorDeDispositivo?.cancel();
        _escuchadorDeDispositivo = null;
        _bandDeEscaneo = false;
        print(" Escaneo detenido");
      }
    } catch (e) {
      print(" Error deteniendo escaneo: $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      print("Conectando a ${device.platformName}...");
      msjRecividosDelESP32?.call("Conectando a ${device.platformName}...");
      
      await device.connect(timeout: Duration(seconds: 20));

    await _escuchadorDeCambConexion?.cancel();

      _dispositivoConectado = device;
      _bandDeConexion = true;
      _bandDeReconexion = false;
      print(" Conectado a ${device.platformName}");
     
      await Future.delayed(Duration(milliseconds: 1000));

      msjRecividosDelESP32?.call(" Descubriendo servicios...");
      List<BluetoothService> services = await device.discoverServices();

      print("Servicios encontrados: ${services.length}");

      bool serviceFound = false;

      // Buscar servicio específico primero
      for (BluetoothService service in services) {
        print("Servicio: ${service.uuid}");

        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          print(" Servicio objetivo encontrado!");
          serviceFound = true;
          await _configureService(service);
          break;
        }
      }

      if (!serviceFound) {
        print(
          " Servicio específico no encontrado, buscando características compatibles...",
        );
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.properties.notify) {
              print(
                " Característica compatible encontrada: ${characteristic.uuid}",
              );
              _canalDeMensajes = characteristic;
              await _comenzaEscucha(characteristic);
              msjRecividosDelESP32?.call(" Servicio configurado correctamente");
              serviceFound = true;
              break;
            }
          }
          if (serviceFound) break;
        }
      }

      if (!serviceFound) {
        throw Exception("No se encontraron servicios compatibles");
      }

      await _escuchadorDeCambConexion?.cancel();
       _escuchadorDeCambConexion = device.connectionState.listen((
        BluetoothConnectionState state,
      ) {
        print("Estado de conexión: $state");
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      estadoConexiconESP32?.call(true);
      msjRecividosDelESP32?.call(
        " Bluetooth conectado correctamente a ${device.platformName}",
      );
    } catch (e) {
      String errorMsg = "Error al conectar: $e";
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call(" $errorMsg");
      _bandDeConexion = false;
      estadoConexiconESP32?.call(false);
      _reintentoDeConexion();
    }
  }

  Future<void> _configureService(BluetoothService service) async {
    for (BluetoothCharacteristic characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toLowerCase() ==
              CHARACTERISTIC_UUID.toLowerCase() ||
          characteristic.properties.notify) {
        _canalDeMensajes = characteristic;
        await _comenzaEscucha(characteristic);
        msjRecividosDelESP32?.call("Caracteristica configurada correctamente");
        break;
      }
    }
  }

  Future<void> _comenzaEscucha(BluetoothCharacteristic characteristic) async {
    try {
      await _escuchadorDeMensaje?.cancel();

      await characteristic.setNotifyValue(true);

      _escuchadorDeMensaje = characteristic.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          try {
            String message = utf8.decode(value);
            print("Mensaje recibido del Esp32: $message");
            _handleReceivedMessage(message);
          } catch (e) {
            print(" Error decodificando mensaje: $e");
          }
        }
      });

      msjRecividosDelESP32?.call("Contigo atento para la ayuda");
    } catch (e) {
      print("Error al configurar notificaciones: $e");
      String errorMsg = "Error al configurar notificaciones: $e";
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call(" $errorMsg");
    }
  }

  void _handleReceivedMessage(String message) {
    msjRecividosDelESP32?.call("Contigo: $message");

    if (message == 'SOS') {
      print('ESTAAAA ENTRAAAANDOOOOO');
      print("¡Mensaje de emergencia detectado!");
      msjRecividosDelESP32?.call(" ¡EMERGENCIA DETECTADA! Enviando SOS...");
      _enviarMensajeSOSAutomatico();
    } else {
      print('NO ESTA ENTRANDOOO ');
    }
  }

  Future<void> _enviarMensajeSOSAutomatico() async {
    try {
      msjRecividosDelESP32?.call("Obteniendo ubicacion...");
      Position posicion = await _obtenerUbicacion();

      msjRecividosDelESP32?.call(" Enviando mensaje SOS...");

      final response = await supabase.functions.invoke(
        'hyper-responder',
        body: {
          'latitud': posicion.latitude, 
          'longitud': posicion.longitude,
          'id':'839e13ed-7b0e-440f-b37d-05b07ae034bf',
          },
      );

      if (response.status == 200) {
        msjRecividosDelESP32?.call(" SOS enviado automáticamente");
      } else {
        throw Exception('Error desde funcion SOS: ${response.data}');
      }
    } catch (e) {
      String errorMsg = "Error al enviar SOS automático: $e";
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call("$errorMsg");
    }
  }

  Future<Position> _obtenerUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw Exception('El servicio de ubicación esta desactivado');
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicacion denegado');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicacion denegado permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _handleDisconnection() {
    print(" ESP32 desconectado");
    msjRecividosDelESP32?.call(" ESP32 desconectado. Reintentando...");

    _bandDeConexion = false;
    _dispositivoConectado = null;
    _canalDeMensajes = null;
    _escuchadorDeMensaje?.cancel();
    estadoConexiconESP32?.call(false);

    if (!_bandDeReconexion) {
      _reintentoDeConexion();
    }
  }

  void _reintentoDeConexion() {
    _bandDeReconexion = true;
    _temporizadorReconexion?.cancel();

    _temporizadorReconexion = Timer(Duration(seconds: 5), () {
      if (!_bandDeConexion) {
        msjRecividosDelESP32?.call("Intentando reconectar...");
        _bandDeReconexion = false;
        autoConectarAlESP32();
      } else {
        _bandDeReconexion = false;
      }
    });
  }

  Future<void> escaneoSeguro() async {
    try {
      if (_bandDeEscaneo) {
        await FlutterBluePlus.stopScan();
        _temporizadorEscaneo?.cancel();
        await _escuchadorDeDispositivo?.cancel();
        _escuchadorDeDispositivo = null;
        _bandDeEscaneo = false;
        print("Escaneo detenido");
      }
    } catch (e) {
      print(" Error deteniendo escaneo: $e");
    }
  }

  Future<void> _cleanup() async {
    print("🧹 Limpiando estado...");
    _temporizadorReconexion?.cancel();
    _temporizadorEscaneo?.cancel();

    if (_bandDeEscaneo) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        print("Error deteniendo escaneo: $e");
      }
    }

    await _escuchadorDeMensaje?.cancel();
    await _escuchadorDeCambConexion?.cancel();
    await _escuchadorDeDispositivo?.cancel();

    _bandDeConexion = false;
    _bandDeReconexion = false;
    _bandDeEscaneo = false;

    _dispositivoConectado = null;
    _canalDeMensajes = null;
    _escuchadorDeMensaje = null;
    _escuchadorDeCambConexion = null;
    _escuchadorDeDispositivo = null;

    print("Estado limpiado");

  }

  Future<bool> enviarMensajeAlESP32(String message) async {
    if (_canalDeMensajes == null || !_bandDeConexion) {
      String errorMsg = "No hay conexion con ESP32";
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call(" $errorMsg");
      return false;
    }

    try {
      List<int> bytes = utf8.encode(message);
      await _canalDeMensajes!.write(bytes);
      print("Mensaje enviado: $message");
      msjRecividosDelESP32?.call(" Enviado: $message");
      return true;
    } catch (e) {
      String errorMsg = "Error al enviar mensaje: $e";
      onError?.call(errorMsg);
      msjRecividosDelESP32?.call(" $errorMsg");
      return false;
    }
  }

  Future<void> disconnectarEsp32() async {
    try {
      _escuchadorDeMensaje?.cancel();
      _temporizadorReconexion?.cancel();
      _temporizadorEscaneo?.cancel();

      if (_dispositivoConectado != null) {
        try {
          await _dispositivoConectado!.disconnect();
          await Future.delayed(Duration(milliseconds: 1500));
          // var state = await _dispositivoConectado!.connectionState.first;
          // if (state != BluetoothConnectionState.disconnected) {
          //   await _dispositivoConectado!.disconnect(); // Intentar de nuevo
          //   await Future.delayed(Duration(milliseconds: 1000));
          // }
        } catch (e) {
          print("Error verificando estado: $e");
        }
      }

      await _cleanup();
      estadoConexiconESP32?.call(false);
      print(" Desconectado del ESP32");
      msjRecividosDelESP32?.call(" Desconectado del Dispositivo Contigo");
    } catch (e) {
      print(" Error al desconectar: $e");
    }
  }

  Future<List<BluetoothDevice>> getAvailableDevices() async {
    List<BluetoothDevice> devices = [];

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      await for (List<ScanResult> results in FlutterBluePlus.scanResults) {
        for (ScanResult result in results) {
          if (result.device.platformName.isNotEmpty &&
              !devices.any((d) => d.remoteId == result.device.remoteId)) {
            devices.add(result.device);
            print(
              "Disponible:${result.device.platformName} - ${result.device.remoteId}",
            );
          }
        }
      }
    } catch (e) {
      print("Error obteniendo dispositivos: $e");
    }

    return devices;
  }

  void dispose() {
    _cleanup();
  }
}
