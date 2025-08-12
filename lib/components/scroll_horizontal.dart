import 'package:contigo_aplicativo/components/imagen_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;

class ScrollHorizontal extends StatefulWidget {
  const ScrollHorizontal({super.key});

  @override
  State<ScrollHorizontal> createState() => _ScrollHorizontalState();
}

class _ScrollHorizontalState extends State<ScrollHorizontal> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _consejos = [];
  bool _isLoading = true;

  Future<void> _cargaConsejos() async {
    try {
      final dataConsejos = await supabase.from('consejos').select();
      setState(() {
        _consejos = List<Map<String, dynamic>>.from(dataConsejos);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _cargaConsejos();
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    // } else if (_consejos.isEmpty) {
    //   return carousel.CarouselSlider(
    //     items: [
    //       ImagenCard(
    //         imagenDirect: 'assets/images/art/art4.jpg',
    //         texto: 'Siempre Avisa a tu grupo de confianza donde estas',
    //       ),
    //       ImagenCard(
    //         imagenDirect: 'assets/images/art/fondo2.png',
    //         texto:
    //             'Si te sintes en una situacion vulnerable pulsa el boton dos segundos',
    //       ),
    //       ImagenCard(
    //         imagenDirect: 'assets/images/art/fondo4.jpg',
    //         texto: 'Crea tu red de apoyo, no estas solo(a)',
    //       ),
    //     ],
    //     options: carousel.CarouselOptions(
    //       height: 180,
    //       autoPlay: true,
    //       autoPlayInterval: const Duration(seconds: 10),
    //       enableInfiniteScroll: true,
    //       enlargeCenterPage: true,
    //       viewportFraction: 0.75,
    //     ),
    //   );
    }

    final List<Widget> carouselItems = _consejos.map<Widget>((item) {
      return ImagenCard(
        imagenDirect: item["url_image"],
        texto: item["text_consejo"] ?? "Bienvenido a ContigoApp",
      );
    }).toList();

    return carousel.CarouselSlider(
      items: carouselItems,
      options: carousel.CarouselOptions(
        height: 180,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 10),
        enableInfiniteScroll: true,
        enlargeCenterPage: true,
        viewportFraction: 0.75,
      ),
    );
  }
}
