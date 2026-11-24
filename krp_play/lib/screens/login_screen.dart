import 'package:flutter/material.dart';
import '../models/student_category.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.completeProfile = false});

  final bool completeProfile;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Using standard GlobalKey to avoid generic bracket deletion
  final _formKey = GlobalKey();
  final _authService = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final matricController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isSignup = false;
  bool acceptedDeclaration = false;
  bool showPassword = false;
  bool isLoading = false;
  StudentCategory category = StudentCategory.krp;
  String message = '';

  final Color primaryGreen = const Color(0xFF103B2B);

  @override
  void initState() {
    super.initState();
    if (widget.completeProfile) {
      isSignup = true;
      emailController.text = Supabase.instance.client.auth.currentUser?.email ?? '';
      message = 'Your account exists, but your profile is incomplete. Please fill in your details and enter your existing password to continue.';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    matricController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  submit() async {
    // Dynamically validate the form
    dynamic formState = _formKey.currentState;
    if (formState != null && !formState.validate()) return;

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      if (isSignup) {
        if (!acceptedDeclaration) {
          throw Exception('Please accept the student declaration.');
        }
        if (passwordController.text != confirmController.text) {
          throw Exception('Passwords do not match.');
        }

        await _authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          fullName: nameController.text.trim(),
          matricNumber: matricController.text.trim(),
          contactNumber: contactController.text.trim(),
          studentCategory: category.value,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.completeProfile
              ? 'Profile saved successfully!'
              : 'Account ready! You are now signed in.'),
        ));
      } else {
        await _authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = AuthService.messageForError(e);
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE9EFEA))),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(color: const Color(0xFFE8F6C8), borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.sports_tennis, size: 32, color: primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('KRP PLAY', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryGreen, letterSpacing: 0.5)),
                      const Text('SPORTS HUB · UTM', textAlign: TextAlign.center, style: TextStyle(letterSpacing: 2.5, fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 28),
                      Text(isSignup ? 'Create your account' : 'Welcome back', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(isSignup ? 'Register to book KRP sports facilities.' : 'Sign in to continue to KRP PLAY.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 24),
                      
                      if (isSignup) ...[
                        _field(nameController, 'Full name', Icons.person_outline),
                        _field(contactController, 'Contact number', Icons.phone_outlined),
                        _field(matricController, 'Matric number', Icons.badge_outlined),
                        const SizedBox(height: 12),
                        // SCRUM-38: options come from StudentCategory, so the
                        // dropdown can only hold a stored value it knows.
                        DropdownButtonFormField<StudentCategory>(
                          isExpanded: true,
                          initialValue: category,
                          decoration: InputDecoration(
                            labelText: 'Student category',
                            prefixIcon: Icon(Icons.school_outlined, color: primaryGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            for (final c in StudentCategory.values)
                              DropdownMenuItem(value: c, child: Text(c.label)),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => category = value);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      _field(emailController, 'Email address', Icons.email_outlined, email: true),
                      _field(passwordController, 'Password', Icons.lock_outline, obscure: !showPassword),
                      
                      if (isSignup) ...[
                        _field(confirmController, 'Confirm password', Icons.lock_outline, obscure: true),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: acceptedDeclaration,
                          onChanged: (value) => setState(() => acceptedDeclaration = value ?? false),
                          title: const Text('I confirm my information is accurate. Management may verify my eligibility.', style: TextStyle(fontSize: 12)),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                      if (!isSignup)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => showPassword = !showPassword),
                            child: Text(showPassword ? 'Hide password' : 'Show password', style: TextStyle(color: primaryGreen)),
                          ),
                        ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(message, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                      const SizedBox(height: 18),
                      
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isLoading ? null : () => submit(),
                        child: isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.completeProfile && isSignup ? 'Save profile' : isSignup ? 'Create account' : 'Sign in', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() {
                          isSignup = !isSignup;
                          message = '';
                        }),
                        child: Text(isSignup ? 'Already have an account? Sign in' : 'New user? Create an account', style: TextStyle(color: primaryGreen)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool email = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen, width: 2)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Please enter $label';
          if (email && !value.contains('@')) return 'Please enter a valid email';
          if (label.contains('Password') && value.length < 6) return 'Use at least 6 characters';
          return null;
        },
      ),
    );
  }
}