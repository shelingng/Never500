import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Sign Up & Create Profile
  signUp({
    required String email,
    required String password,
    required String fullName,
    required String matricNumber,
    required String contactNumber,
    required String studentCategory,
  }) async {
    // 1. Create user in Supabase Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Sign up failed.');

    // 2. Insert user details into public.profiles table
    await _supabase.from('profiles').insert({
      'id': user.id, // Matches auth.users UUID
      'email': email,
      'full_name': fullName,
      'matric_number': matricNumber.isEmpty ? null : matricNumber,
      'phone_number': contactNumber,
      'student_category': studentCategory,
      'role': 'student', // Default role matching schema
    });
  }

  // Sign In
  signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  signOut() async {
    await _supabase.auth.signOut();
  }

  // Fetch Current User Profile
  getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return data;
  }
}