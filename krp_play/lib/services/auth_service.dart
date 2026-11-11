import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 登录并返回用户角色 ('student' 或 'admin')
  Future<String?> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // 查询 profiles 表获取用户权限角色
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', response.user!.id)
          .single();
      return data['role'] as String?;
    }
    return null;
  }

  // 注册新学生
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String contact,
    required String matric,
    required String category,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // 注册成功后，将额外信息存入 profiles 表
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'email':email,         
        'full_name': fullName,
        'phone_number': contact,            // 必须是 phone_number
        'matric_number': matric,            // 必须是 matric_number
        'student_category': category,       // 🚨 关键修改：左边必须改成 student_category 
        'role': 'student',
      });
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}