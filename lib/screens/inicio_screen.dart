import 'package:contigo_aplicativo/components/cabecera_logo.dart';
import 'package:contigo_aplicativo/components/image_inicio.dart';
import 'package:contigo_aplicativo/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  bool mRegistro=false;
  final supabase= Supabase.instance.client;

  Future<void> Login(String email,String clave) async{
    try{
      final respose=await supabase.auth.signInWithPassword(
        email: email,
        password: clave,
        );
      if(respose.user!=null){
          Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context)=>Home()),
          );
      }else{
        ScaffoldMessenger.of(context,).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesion'),));
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'),));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
    );
  }
}