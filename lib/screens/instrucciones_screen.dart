import 'package:flutter/material.dart';

class InstruccionesScreen extends StatelessWidget {
  const InstruccionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color.fromARGB(255, 237, 220, 255)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/brand/logo1.png',
                    fit: BoxFit.contain,
                    width: 200,
                  ),
                  const SizedBox(height: 40),

                  const SizedBox(height: 16),

                  const Text(
                    'Presentación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bienvenido a Contigo, una aplicación diseñada para conectar con tu red de apoyo y brindarte seguridad. '
                    'Mantén a los tuyos cerca, entre todos nos cuidamos.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Con esta app podrás registrar los contactos de tu red de apoyo. Cuando te sientas vulnerable o en una situación de riesgo, '
                    'podrás enviarles un mensaje SOS con tu ubicación GPS en tiempo real, para que tus familiares y amigos sepan dónde estás '
                    'y te puedan ayudar.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Uso básico',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Registra los contactos de confianza en la sección Mi red de apoyo.\n\n'
                    '• En pantalla tendrás un botón SOS que, al activarse, enviará tu ubicación a los contactos seleccionados.\n\n'
                    '• El sistema está pensado para actuar rápido y con un dos toques, sin necesidad de buscar números o escribir mensajes.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'El dispositivo Contigo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El dispositivo Contigo alimentado por una batería recargable LiPo de 3.7 V. '
                    'Cuenta con un botón físico que, al mantenerlo presionado por 2 segundos, enviará automáticamente la señal de SOS '
                    'a tu red de apoyo registrada en la app.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Carga de la batería',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Puedes cargarlo directamente usando el puerto USB de tu laptop.\n\n'
                    '• También es posible cargarlo con un cargador de teléfono, siempre que el voltaje de salida sea 5 V y la corriente no supere los 2 A.\n\n'
                    '• Usa únicamente cables y cargadores de buena calidad para evitar daños a la batería.\n\n'
                    '• No dejes la batería cargando por más de 4 horas seguidas y evita temperaturas extremas.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Verificación de conexión',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'En el apartado Monitor de la aplicación podrás ver si el dispositivo está conectado o no. '
                    'Es fundamental asegurarse de que el dispositivo tenga suficiente carga para que el SOS pueda enviarse correctamente en cualquier momento que lo necesites.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '¿Quieres que integre este texto formateado en la pantalla con el degradado y la imagen fija que hicimos antes?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/art/instrucciones.png',
              fit: BoxFit.cover,
              height: 300,
            ),
          ),
        ],
      ),
    );
  }
}
