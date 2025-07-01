import 'package:flutter/material.dart';

class CabeceraLogo extends StatelessWidget {
  const CabeceraLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      
      padding: const EdgeInsets.all(16.0),
      
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 40),
          
          Image.asset("assets/images/brand/logo1.png", height: 30),
          
        ],
      ),
    );
  }
}