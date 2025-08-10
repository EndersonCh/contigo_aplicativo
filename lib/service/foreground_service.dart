import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:contigo_aplicativo/service/bluetooth_service.dart';

class ForegroundService {
  static bool _isRunning = false;
  static ESP32BluetoothService? _bluetoothService;

  static bool get isRunning => _isRunning;

  /// Inicializar el servicio en primer plano
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
        interval: 5000, // Verificar cada 5 segundos
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Iniciar el servicio en primer plano
  static Future<bool> startService() async {
    if (_isRunning) {
      print("⚠️ El servicio ya está ejecutándose");
      return true;
    }

    try {
      // Solicitar permisos de batería (opcional pero recomendado)
      if (!await FlutterForegroundTask.canDrawOverlays) {
        await FlutterForegroundTask.openSystemAlertWindowSettings();
      }

      // Inicializar servicio Bluetooth
      _bluetoothService = ESP32BluetoothService();
      
      // Configurar callbacks
      _bluetoothService!.onMessageReceived = (message) {
        _updateNotification("Mensaje recibido: $message");
      };
      
      _bluetoothService!.onConnectionStatusChanged = (isConnected) {
        if (isConnected) {
          _updateNotification("✅ ESP32 conectado - Escuchando...");
        } else {
          _updateNotification("🔍 Buscando ESP32...");
        }
      };
      
      _bluetoothService!.onError = (error) {
        _updateNotification("❌ Error: $error");
      };

      // Inicializar Bluetooth
      bool bluetoothInitialized = await _bluetoothService!.initialize();
      if (!bluetoothInitialized) {
        print("❌ No se pudo inicializar Bluetooth");
        return false;
      }

      // Iniciar el servicio en primer plano
      bool serviceStarted = await FlutterForegroundTask.startService(
        notificationTitle: 'Contigo - Protección Activa',
        notificationText: 'Inicializando servicio...',
        callback: _foregroundTaskCallback,
      );

      if (serviceStarted) {
        _isRunning = true;
        print("✅ Servicio en primer plano iniciado");
        
        // Comenzar búsqueda automática de ESP32
        await _bluetoothService!.startAutoConnect();
        return true;
      } else {
        print("❌ No se pudo iniciar el servicio en primer plano");
        return false;
      }

    } catch (e) {
      print("❌ Error al iniciar servicio: $e");
      return false;
    }
  }

  /// Detener el servicio en primer plano
  static Future<void> stopService() async {
    try {
      await _bluetoothService?.disconnect();
      await FlutterForegroundTask.stopService();
      _isRunning = false;
      _bluetoothService = null;
      print("🛑 Servicio en primer plano detenido");
    } catch (e) {
      print("❌ Error al detener servicio: $e");
    }
  }

  /// Actualizar la notificación
  static void _updateNotification(String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Contigo - Protección Activa',
      notificationText: text,
    );
  }

  /// Callback del servicio en primer plano
  @pragma('vm:entry-point')
  static void _foregroundTaskCallback() {
    // Esta función se ejecuta periódicamente en segundo plano
    print("🔄 Servicio ejecutándose en segundo plano...");
    
    // Verificar conexión Bluetooth
    if (_bluetoothService != null) {
      if (!_bluetoothService!.isConnected) {
        print("🔍 Verificando conexión ESP32...");
        _bluetoothService!.startAutoConnect();
      }
    }
  }

  /// Obtener estado del servicio
  static Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Reanudar el servicio si estaba ejecutándose
  static Future<void> resumeService() async {
    if (await isServiceRunning()) {
      _isRunning = true;
      _bluetoothService = ESP32BluetoothService();
      print("🔄 Servicio reanudado");
    }
  }
}