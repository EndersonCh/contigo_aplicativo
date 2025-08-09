import 'package:contigo_aplicativo/screens/home.dart';
// import 'package:contigo_aplicativo/screens/inicio_screen.dart';
//import 'package:contigo_aplicativo/screens/inicio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
//  await dotenv.load();
  String supabaseUrl='https://wwizimtpwsbfrhneezqh.supabase.co';
  String supabaseAnonKey='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind3aXppbXRwd3NiZnJobmVlenFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MDkwOTAsImV4cCI6MjA3MDE4NTA5MH0._qfzCWAoBg_FZIrLnwfA20421aaR4kqy1G72HD4uQ_g';
  print('Supabase URL: $supabaseUrl');
  print('Supabase anon key: $supabaseAnonKey');
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      home: Scaffold(
        body:const Home(),
      ),
    );
  }
}
