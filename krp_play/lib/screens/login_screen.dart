import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart'; // 引入管理员页面

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

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
  String category = 'KRP Student';
  String message = '';

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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
      message = '';
    });

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    try {
      if (isSignup) {
        if (!acceptedDeclaration) {
          throw Exception('Please accept the student declaration.');
        }
        if (password != confirmController.text) {
          throw Exception('Passwords do not match.');
        }
        
        await _authService.signUp(
          email: email,
          password: password,
          fullName: nameController.text.trim(),
          contact: contactController.text.trim(),
          matric: matricController.text.trim(),
          category: category,
        );
        
        setState(() {
          isSignup = false;
          message = 'Account created successfully! Please sign in.';
        });
      } else {
        final role = await _authService.signIn(email: email, password: password);
        
        if (!mounted) return;
        // 核心路由逻辑：根据权限身份跳转不同页面
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => message = e.message);
    } catch (e) {
      setState(() => message = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.sports_tennis, size: 56, color: Color(0xFF173F32)),
                      const SizedBox(height: 12),
                      const Text(
                        'KRP PLAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF173F32),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        isSignup ? 'Create Account' : 'Welcome Back',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSignup ? 'Register to book facilities' : 'Sign in to your account',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // 动态展开注册字段
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: [
                            _field(nameController, 'Full name', Icons.person_outline, isSignupField: true),
                            _field(contactController, 'Contact number', Icons.phone_outlined, isSignupField: true),
                            _field(matricController, 'Matric number', Icons.badge_outlined, isSignupField: true),
                            DropdownButtonFormField<String>(
                              value: category,
                              decoration: const InputDecoration(
                                labelText: 'Student category',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'KRP Student', child: Text('KRP Student')),
                                DropdownMenuItem(value: 'Non-KRP Student', child: Text('Non-KRP Student')),
                              ],
                              onChanged: (val) => setState(() => category = val!),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        crossFadeState: isSignup ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      _field(emailController, 'Email address', Icons.email_outlined, email: true),
                      _field(passwordController, 'Password', Icons.lock_outline, obscure: !showPassword),

                      if (isSignup) ...[
                        _field(confirmController, 'Confirm password', Icons.lock_outline, obscure: !showPassword),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: acceptedDeclaration,
                          onChanged: (val) => setState(() => acceptedDeclaration = val ?? false),
                          title: const Text(
                            'I verify my information is accurate.',
                            style: TextStyle(fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => showPassword = !showPassword),
                          child: Text(showPassword ? 'Hide password' : 'Show password'),
                        ),
                      ),

                      if (message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(message, style: TextStyle(color: message.contains('success') ? Colors.green : Colors.red)),
                        ),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isSignup ? 'Create Account' : 'Sign In', style: const TextStyle(fontSize: 16)),
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() {
                          isSignup = !isSignup;
                          message = '';
                        }),
                        child: Text(isSignup ? 'Already have an account? Sign in' : 'New user? Create an account'),
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

  Widget _field(TextEditingController controller, String label, IconData icon, {bool email = false, bool obscure = false, bool isSignupField = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          // 🚨 核心修复：如果是登录模式，且当前是注册专属字段，直接跳过校验！
          if (isSignupField && !isSignup) return null;

          if (value == null || value.trim().isEmpty) return 'Please enter $label';
          if (email && !value.contains('@')) return 'Invalid email';
          if (label == 'Password' && value.length < 6) return 'At least 6 characters';
          return null;
        },
      ),
    );
  }
}