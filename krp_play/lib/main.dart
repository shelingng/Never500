import 'screens/facilities_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ckhpsnuiypxetkmigqua.supabase.co',
    anonKey: 'sb_publishable_jByO0pC0UVwMS5Jr1v5jhQ_VaCx8NV5',
  );

  runApp(const KrpPlayApp());
}

class StudentAccount {
  final String fullName;
  final String email;
  final String contact;
  final String matric;
  final String category;
  final String password;

  StudentAccount({
    required this.fullName,
    required this.email,
    required this.contact,
    required this.matric,
    required this.category,
    required this.password,
  });
}

class KrpPlayApp extends StatefulWidget {
  const KrpPlayApp({super.key});

  @override
  State<KrpPlayApp> createState() => _KrpPlayAppState();
}

class _KrpPlayAppState extends State<KrpPlayApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KRP PLAY',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173F32)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
      ),
      // 更改这里：不再判断 currentAccount，直接去登录页，后续逻辑交给 Supabase
      home: const LoginScreen(), 
    );
  }
}



