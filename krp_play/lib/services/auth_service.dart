import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  /// Keep provider errors and database details out of user-facing messages.
  static String messageForError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'Email or password is incorrect. New here? Please register first.';
        case 'email_not_confirmed':
          return 'Please verify your email before signing in. Check your inbox and spam folder.';
        case 'user_already_exists':
          return 'An account with this email already exists. Please sign in.';
        case 'weak_password':
          return 'Please choose a stronger password with at least 6 characters.';
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'signup_disabled':
          return 'Registration is temporarily unavailable. Please try again later.';
        case 'email_address_invalid':
          return 'Please enter a valid email address.';
      }
    }
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return 'These profile details are already in use. Check your matric number and email, or sign in to your existing account.';
      }
      return 'We couldn’t save or load your profile. Please try again.';
    }
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed to fetch') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timed out') ||
        lower.contains('timeoutexception')) {
      return 'Unable to connect. Check your internet connection and try again.';
    }
    const formMessages = [
      'Please accept the student declaration.',
      'Passwords do not match.',
      'Please enter your name and student category.',
      'Sign in to complete registration.',
    ];
    final clean = text.replaceFirst('Exception: ', '');
    if (formMessages.contains(clean) ||
        clean.startsWith('Check your email to confirm registration')) {
      return clean;
    }
    return 'We couldn’t complete your request. Please try again.';
  }

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
    final details = <String, dynamic>{
      'full_name': fullName.trim(),
      'matric_number': matricNumber.trim().isEmpty ? null : matricNumber.trim(),
      'phone_number': contactNumber.trim(),
      'student_category': studentCategory,
    };
    if (fullName.trim().isEmpty ||
        !['krp', 'non_krp'].contains(studentCategory)) {
      throw Exception('Please enter your name and student category.');
    }

    // A signed-in account without a profile must complete registration.
    // Verify the password before writing any profile for an existing account.
    if (_supabase.auth.currentUser?.email?.toLowerCase() ==
        email.toLowerCase()) {
      await signIn(email: email, password: password);
    } else {
      try {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: details,
        );
        if (response.session == null) {
          throw Exception(
            'Check your email to confirm registration, then sign in. '
            'If this account already exists, sign in to complete its profile.',
          );
        }
      } on AuthException catch (error) {
        if (error.code != 'user_already_exists') rethrow;
        await signIn(email: email, password: password);
      }
    }

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Sign in to complete registration.');
    final existing = await getCurrentProfile();
    if (existing == null) {
      // Recovery for accounts created before the atomic signup trigger.
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        ...details,
        'role': 'student',
      });
    }
    // Emit a fresh auth event after the profile exists so AuthWrapper reloads.
    await _supabase.auth.refreshSession();
  }

  // Sign In
  signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
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
        .maybeSingle();

    return data;
  }
}
