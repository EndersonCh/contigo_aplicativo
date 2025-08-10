import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ESP32BluetoothService {
  static final ESP32BluetoothService _instance = ESP32BluetoothService._internal();
  factory ESP32BluetoothService() => _instance;
  ESP32BluetoothService._internal();

  final supabase = Supabase.instance.client;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  Timer? _scanTimeout;

  // Configuración del ESP32
  static const String ESP32_NAME = "CONTIGO-SOS";
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Callbacks para notificar eventos
  Function(String)? onMessageReceived;
  Function(bool)? onConnectionStatusChanged;
  Function(String)? onError;

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Inicializar el servicio Bluetooth
  Future<bool> initialize() async {
    try {
      print("🔧 Inicializando ESP32BluetoothService...");
      
      // Limpiar cualquier conexión anterior
      await _cleanup();
      
      // Verificar si Bluetooth está disponible
      if (!await FlutterBluePlus.isSupported) {
        String errorMsg = "Bluetooth no es soportado en este dispositivo";
        onError?.call(errorMsg);
        onMessageReceived?.call("❌ $errorMsg");
        return false;
      }

      // Solicitar permisos necesarios
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        String errorMsg = "Permisos de Bluetooth denegados";
        onError?.call(errorMsg);
        onMessageReceived?.call("❌ $errorMsg");
        return false;
      }

      // Verificar estado de Bluetooth
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        String errorMsg = "Bluetooth está desactivado. Por favor actívalo";
        onError?.call(errorMsg);
        onMessageReceived?.call("❌ $errorMsg");
        return false;
      }

      print("✅ ESP32 Bluetooth Service inicializado correctamente");
      onMessageReceived?.call("🔵 Bluetooth inicializado correctamente");
      return true;
      
    } catch (e) {
      String errorMsg = "Error al inicializar Bluetooth: $e";
      print("❌ $errorMsg");
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
      return false;
    }
  }

  /// Solicitar permisos necesarios
  Future<bool> _requestPermissions() async {
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
          print("⚠️ Permiso denegado: $permission");
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      print("❌ Error solicitando permisos: $e");
      return false;
    }
  }

  /// Buscar y conectar automáticamente al ESP32
  Future<void> startAutoConnect() async {
    if (_isScanning) {
      print("⚠️ Ya hay un escaneo en progreso");
      return;
    }

    try {
      _isScanning = true;
      print("🔍 Iniciando búsqueda de ESP32...");
      onMessageReceived?.call("🔍 Buscando dispositivo ESP32...");

      // Cancelar timeout anterior si existe
      _scanTimeout?.cancel();

      // Configurar timeout para el escaneo
      _scanTimeout = Timer(Duration(seconds: 20), () async {
        if (_isScanning) {
          await _stopScan();
          if (!_isConnected && !_isReconnecting) {
            onMessageReceived?.call("⏰ Tiempo de búsqueda agotado. Reintentando...");
            _scheduleReconnect();
          }
        }
      });

      // Cancelar suscripción anterior si existe
      await _scanSubscription?.cancel();

      // Configurar listener de resultados de escaneo
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          String deviceName = result.device.platformName;
          String deviceId = result.device.remoteId.toString();
          
          print("📱 Dispositivo encontrado: '$deviceName' (ID: $deviceId)");
          
          // Búsqueda del ESP32
          if (_isTargetDevice(deviceName)) {
            print("🎯 ESP32 objetivo encontrado: $deviceName");
            onMessageReceived?.call("🎯 ESP32 encontrado: $deviceName");
            
            await _stopScan();
            await _connectToDevice(result.device);
            break;
          }
        }
      });

      // Iniciar escaneo
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      print("📡 Escaneo iniciado correctamente");

    } catch (e) {
      String errorMsg = "Error en escaneo: $e";
      print("❌ $errorMsg");
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
      _isScanning = false;
    }
  }

  /// Verificar si un dispositivo es nuestro ESP32 objetivo
  bool _isTargetDevice(String deviceName) {
    if (deviceName.isEmpty) return false;
    
    String upperName = deviceName.toUpperCase();
    
    // Verificación exacta primero
    if (upperName == ESP32_NAME.toUpperCase()) {
      return true;
    }
    
    // Verificaciones alternativas
    if (upperName.contains("CONTIGO") || 
        upperName.contains("SOS") || 
        upperName.contains("ESP32")) {
      return true;
    }
    
    return false;
  }

  /// Detener escaneo de forma segura
  Future<void> _stopScan() async {
    try {
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
        _scanTimeout?.cancel();
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _isScanning = false;
        print("🛑 Escaneo detenido");
      }
    } catch (e) {
      print("❌ Error deteniendo escaneo: $e");
    }
  }

  /// Conectar a un dispositivo específico
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      print("🔄 Conectando a ${device.platformName}...");
      onMessageReceived?.call("🔄 Conectando a ${device.platformName}...");

      // Cancelar conexión anterior si existe
      await _connectionSubscription?.cancel();

      // Conectar al dispositivo
      await device.connect(timeout: Duration(seconds: 20));
      
      _connectedDevice = device;
      _isConnected = true;
      _isReconnecting = false;
      
      print("✅ Conectado a ${device.platformName}");
      onConnectionStatusChanged?.call(true);
      onMessageReceived?.call("✅ Bluetooth conectado correctamente a ${device.platformName}");

      // Configurar listener de estado de conexión
      _connectionSubscription = device.connectionState.listen((BluetoothConnectionState state) {
        print("🔄 Estado de conexión: $state");
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Pausa antes de descubrir servicios
      await Future.delayed(Duration(milliseconds: 1000));

      // Descubrir servicios
      onMessageReceived?.call("🔍 Descubriendo servicios...");
      List<BluetoothService> services = await device.discoverServices();
      
      print("📋 Servicios encontrados: ${services.length}");
      
      bool serviceFound = false;
      
      // Buscar servicio específico primero
      for (BluetoothService service in services) {
        print("🛠️ Servicio: ${service.uuid}");
        
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          print("🎯 Servicio objetivo encontrado!");
          serviceFound = true;
          await _configureService(service);
          break;
        }
      }
      
      // Si no se encuentra el servicio específico, buscar características compatibles
      if (!serviceFound) {
        print("⚠️ Servicio específico no encontrado, buscando características compatibles...");
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.properties.notify) {
              print("🔧 Característica compatible encontrada: ${characteristic.uuid}");
              _targetCharacteristic = characteristic;
              await _startListening(characteristic);
              onMessageReceived?.call("🔧 Servicio configurado correctamente");
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

    } catch (e) {
      print("❌ Error al conectar: $e");
      String errorMsg = "Error al conectar: $e";
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
      _isConnected = false;
      onConnectionStatusChanged?.call(false);
      
      // Programar reintento
      _scheduleReconnect();
    }
  }

  /// Configurar servicio específico
  Future<void> _configureService(BluetoothService service) async {
    for (BluetoothCharacteristic characteristic in service.characteristics) {
      print("📡 Característica: ${characteristic.uuid}");
      
      if (characteristic.uuid.toString().toLowerCase() == CHARACTERISTIC_UUID.toLowerCase() ||
          characteristic.properties.notify) {
        
        print("🎯 Característica objetivo encontrada!");
        _targetCharacteristic = characteristic;
        await _startListening(characteristic);
        onMessageReceived?.call("🔧 Característica configurada correctamente");
        break;
      }
    }
  }

  /// Comenzar a escuchar mensajes de la característica
  Future<void> _startListening(BluetoothCharacteristic characteristic) async {
    try {
      print("🔧 Configurando característica para notificaciones...");
      
      // Cancelar suscripción anterior
      await _characteristicSubscription?.cancel();
      
      // Habilitar notificaciones
      await characteristic.setNotifyValue(true);
      
      // Escuchar cambios en la característica
      _characteristicSubscription = characteristic.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          try {
            String message = utf8.decode(value);
            print("📨 Mensaje recibido del ESP32: $message");
            _handleReceivedMessage(message);
          } catch (e) {
            print("❌ Error decodificando mensaje: $e");
          }
        }
      });

      print("👂 Escuchando mensajes del ESP32...");
      onMessageReceived?.call("👂 Listo para recibir mensajes del ESP32");
      
    } catch (e) {
      print("❌ Error al configurar notificaciones: $e");
      String errorMsg = "Error al configurar notificaciones: $e";
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
    }
  }

  /// Manejar mensaje recibido del ESP32
  void _handleReceivedMessage(String message) {
    onMessageReceived?.call("📨 ESPPPPP: $message");
    
    // Si el mensaje es "SOS" o contiene "EMERGENCY", enviar mensaje automáticamente
    if (message=='SOS') {
      print('ESTAAAA ENTRAAAANDOOOOO');
      print("🚨 ¡Mensaje de emergencia detectado!");
      onMessageReceived?.call("🚨 ¡EMERGENCIA DETECTADA! Enviando SOS...");
      _enviarMensajeSOSAutomatico();
    }else{
      print('NO ESTA ENTRANDOOO ');
    }
  }

  /// Enviar mensaje SOS automáticamente cuando llega la señal del ESP32
  Future<void> _enviarMensajeSOSAutomatico() async {
    try {
      print("📍 Obteniendo ubicación...");
      onMessageReceived?.call("📍 Obteniendo ubicación...");
      Position posicion = await _obtenerUbicacion();
      
      print("📤 Enviando mensaje SOS automático...");
      onMessageReceived?.call("📤 Enviando mensaje SOS...");
      
      final response = await supabase.functions.invoke('hyper-responder', body: {
        'latitud': posicion.latitude,
        'longitud': posicion.longitude,
        // 'origen': 'esp32_automatico',
      });

      if (response.status == 200) {
        print("✅ Mensaje SOS enviado exitosamente");
        onMessageReceived?.call("✅ SOS enviado automáticamente");
      } else {
        throw Exception('Error desde función SOS: ${response.data}');
      }

    } catch (e) {
      print("❌ Error al enviar SOS automático: $e");
      String errorMsg = "Error al enviar SOS automático: $e";
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
    }
  }

  /// Obtener ubicación actual
  Future<Position> _obtenerUbicacion() async {
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

  /// Manejar desconexión
  void _handleDisconnection() {
    print("🔌 ESP32 desconectado");
    onMessageReceived?.call("🔌 ESP32 desconectado. Reintentando...");
    
    _isConnected = false;
    _connectedDevice = null;
    _targetCharacteristic = null;
    _characteristicSubscription?.cancel();
    onConnectionStatusChanged?.call(false);
    
    // Intentar reconectar después de 5 segundos si no se está reconectando ya
    if (!_isReconnecting) {
      _scheduleReconnect();
    }
  }

  /// Programar reintento de conexión
  void _scheduleReconnect() {
    _isReconnecting = true;
    _reconnectTimer?.cancel();
    
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      if (!_isConnected) {
        print("🔄 Intentando reconectar...");
        onMessageReceived?.call("🔄 Intentando reconectar...");
        _isReconnecting = false;
        startAutoConnect();
      } else {
        _isReconnecting = false;
      }
    });
  }

  /// Detener escaneo de forma segura
  Future<void> escaneoSefuro() async {
    try {
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
        _scanTimeout?.cancel();
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _isScanning = false;
        print("🛑 Escaneo detenido");
      }
    } catch (e) {
      print("❌ Error deteniendo escaneo: $e");
    }
  }

  /// Limpiar recursos
  Future<void> _cleanup() async {
    _isConnected = false;
    _isReconnecting = false;
    _connectedDevice = null;
    _targetCharacteristic = null;
    
    await _characteristicSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _scanSubscription?.cancel();
    
    _characteristicSubscription = null;
    _connectionSubscription = null;
    _scanSubscription = null;
    
    _reconnectTimer?.cancel();
    _scanTimeout?.cancel();
  }

  /// Enviar mensaje al ESP32
  Future<bool> sendMessage(String message) async {
    if (_targetCharacteristic == null || !_isConnected) {
      String errorMsg = "No hay conexión con ESP32";
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
      return false;
    }

    try {
      List<int> bytes = utf8.encode(message);
      await _targetCharacteristic!.write(bytes);
      print("📤 Mensaje enviado: $message");
      onMessageReceived?.call("📤 Enviado: $message");
      return true;
    } catch (e) {
      String errorMsg = "Error al enviar mensaje: $e";
      onError?.call(errorMsg);
      onMessageReceived?.call("❌ $errorMsg");
      return false;
    }
  }

  /// Desconectar del ESP32
  Future<void> disconnect() async {
    try {
      _characteristicSubscription?.cancel();
      _reconnectTimer?.cancel();
      _scanTimeout?.cancel();
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      
      await _cleanup();
      onConnectionStatusChanged?.call(false);
      print("🔌 Desconectado del ESP32");
      onMessageReceived?.call("🔌 Desconectado del ESP32");
      
    } catch (e) {
      print("❌ Error al desconectar: $e");
    }
  }

  /// Obtener lista de dispositivos disponibles (para debug)
  Future<List<BluetoothDevice>> getAvailableDevices() async {
    List<BluetoothDevice> devices = [];
    
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
      
      await for (List<ScanResult> results in FlutterBluePlus.scanResults) {
        for (ScanResult result in results) {
          if (result.device.platformName.isNotEmpty && 
              !devices.any((d) => d.remoteId == result.device.remoteId)) {
            devices.add(result.device);
            print("📱 Disponible: ${result.device.platformName} - ${result.device.remoteId}");
          }
        }
      }
    } catch (e) {
      print("❌ Error obteniendo dispositivos: $e");
    }
    
    return devices;
  }

  /// Limpiar recursos al destruir
  void dispose() {
    _cleanup();
  }
}