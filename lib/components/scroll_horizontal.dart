import 'package:contigo_aplicativo/components/imagen_card.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;


class ScrollHorizontal extends StatefulWidget {
  const ScrollHorizontal({super.key});

  @override
  State<ScrollHorizontal> createState() => _ScrollHorizontalState();
}

class _ScrollHorizontalState extends State<ScrollHorizontal> {
  @override
  Widget build(BuildContext context) {
    return carousel.CarouselSlider(
      items: [
        ImagenCard(
          imagenDirect:'assets/images/art/art4.jpg', 
          texto: 'Siempre Avisa a tu grupo de confianza donde estas'),
        ImagenCard(
          imagenDirect:'assets/images/art/fondo2.png', 
          texto: 'Usa SOS '),
        ImagenCard(
          imagenDirect:'assets/images/art/fondo3.png', 
          texto: 'mANTENTE Alerte'),
        ImagenCard(
          imagenDirect:'assets/images/art/fondo4.jpg', 
          texto: 'LLama a tu mamá'),
      ], 
      options: carousel.CarouselOptions(
        height: 180,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 10),
        enableInfiniteScroll: true,
        enlargeCenterPage: true,
        viewportFraction: 0.75,
      ));
  }
}

    
    
//     SizedBox(
//       height: 200,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         child: Row(
//           children: [
//             ImagenCard(
//               imagenDirect:'assets/images/art/art4.jpg', 
//               texto: 'Siempre Avisa a tu grupo de confianza donde estas'),
//             ImagenCard(
//               imagenDirect:'assets/images/art/fondo2.png', 
//               texto: 'Usa SOS '),
//             ImagenCard(
//               imagenDirect:'assets/images/art/fondo3.png', 
//               texto: 'mANTENTE Alerte'),
//             ImagenCard(
//               imagenDirect:'assets/images/art/fondo4.jpg', 
//               texto: 'LLama a tu mamá'),
//           ],
          
//         ),
//       ),
//     );
//   }
// }