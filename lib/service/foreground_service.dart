import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:contigo_aplicativo/service/bluetooth_service.dart';

class ForegroundService {
  static bool _isRunning = false;
  static ESP32BluetoothService? _bluetoothService;

  static bool get isRunning => _isRunning;

  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'contigo_bluetooth_service',
        channelName: 'Contigo Bluetooth Service',
        channelDescription: 'Servicio para escuchar ESP32 en segundo plano',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startService() async {
    if (_isRunning) {
      print("El servicio ya está ejecutándose");
      return true;
    }

    try {
      _bluetoothService = ESP32BluetoothService();
      
      _bluetoothService!.msjRecividosDelESP32 = (message) {
        _updateNotification("Mensaje recibido: $message");
      };
      
      _bluetoothService!.estadoConexiconESP32 = (estaConectado) {
        if (estaConectado) {
          _updateNotification(" ESP32 conectado - Escuchando...");
        } else {
          _updateNotification("Buscando ESP32...");
        }
      };
      
      _bluetoothService!.onError = (error) {
        _updateNotification(" Error: $error");
      };

      bool bluetoothInitialized = await _bluetoothService!.inicializarBluetooth();
      if (!bluetoothInitialized) {
        print(" No se pudo inicializar Bluetooth");
        return false;
      }

      bool serviceStarted = await FlutterForegroundTask.startService(
        notificationTitle: 'Contigo - Protección Activa',
        notificationText: 'Inicializando servicio...',
        callback: _foregroundTaskCallback,
      );

      if (serviceStarted) {
        _isRunning = true;
        print(" Servicio en primer plano iniciado");
        
        await _bluetoothService!.autoConectarAlESP32();
        return true;
      } else {
        print("No se pudo iniciar el servicio en primer plano");
        return false;
      }

    } catch (e) {
      print(" Error al iniciar servicio: $e");
      return false;
    }
  }

  static Future<void> stopService() async {
    try {
      await _bluetoothService?.disconnectarEsp32();
      await FlutterForegroundTask.stopService();
      _isRunning = false;
      _bluetoothService = null;
      print(" Servicio en primer plano detenido");
    } catch (e) {
      print(" Error al detener servicio: $e");
    }
  }

  static void _updateNotification(String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Contigo - Protección Activa',
      notificationText: text,
    );
  }

  @pragma('vm:entry-point')
  static void _foregroundTaskCallback() {
    
    print(" Servicio ejecutándose en segundo plano...");
    
    if (_bluetoothService != null) {
      if (!_bluetoothService!.estaConectado) {
        print(" Verificando conexion ESP32...");
        _bluetoothService!.autoConectarAlESP32();
      }
    }
  }

  static Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  static Future<void> resumeService() async {
    if (await isServiceRunning()) {
      _isRunning = true;
      _bluetoothService = ESP32BluetoothService();
      print(" Servicio reanudado");
    }
  }
}