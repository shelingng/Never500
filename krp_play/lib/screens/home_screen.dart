import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 新增：引入 Supabase
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'facilities_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: FilledButton.icon(
          onPressed: () {
            // 从 Supabase 获取当前登录的用户信息
            final user = Supabase.instance.client.auth.currentUser;
            final userEmail = user?.email ?? 'Unknown User';

            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => FacilitiesScreen(
                  category: 'KRP Student', // 这里暂时默认，若要真实分类需从 profiles 表查询
                  email: userEmail,        // 传入 Supabase 拿到的真实邮箱
                ),
              ),
            );
          },
          icon: const Icon(Icons.sports_tennis),
          label: const Text('Book a Facility'),
        ),
      ),
    );
  }
}