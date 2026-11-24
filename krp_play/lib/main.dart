import 'package:flutter/material.dart';
import 'models/student_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/facility_info_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://ckhpsnuiypxetkmigqua.supabase.co',
    anonKey: 'sb_publishable_jByO0pC0UVwMS5Jr1v5jhQ_VaCx8NV5'
  );

  runApp(const KrpPlayApp());
}

class KrpPlayApp extends StatelessWidget {
  const KrpPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KRP PLAY',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF103B2B),
          primary: const Color(0xFF103B2B),
          secondary: const Color(0xFFD2F865),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to Supabase authentication state changes
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Dynamically get the session to avoid copy-paste bracket issues
        dynamic data = snapshot.data;
        final session = data?.session;

        // If no session exists, show Login Screen
        if (session == null) {
          return const AuthScreen();
        }

        // If session exists, fetch profile to determine role
        return FutureBuilder(
          future: AuthService().getCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            dynamic profile = profileSnapshot.data;
            if (profileSnapshot.hasError) {
              return Scaffold(body: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('We couldn’t load your profile. Please sign in again to retry.'),
                  TextButton(onPressed: () => AuthService().signOut(),
                    child: const Text('Sign out')),
                ],
              )));
            }
            if (profile == null) return const AuthScreen(completeProfile: true);

            // Route based on role from public.profiles
            if (profile['role'] == 'admin') {
              return AdminHomeScreen(onLogout: () => AuthService().signOut());
            } else {
              return FacilityInfoScreen(
                // SCRUM-38: pass the stored value (krp / non_krp), or '' if not set.
                category: StudentCategory.parse(profile['student_category'])?.value ?? '',
                email: profile['email'] ?? '',
                studentName: profile['full_name'] ?? '',
                contact: profile['phone_number'] ?? '',
                matric: profile['matric_number'] ?? '',
                onLogout: () => AuthService().signOut(),
              );
            }
          },
        );
      },
    );
  }
}
