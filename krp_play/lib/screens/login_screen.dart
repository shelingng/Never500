import 'package:flutter/material.dart';
import '../models/student_account.dart';

class AuthScreen extends StatefulWidget {
  final List<StudentAccount> accounts;
  final Function(StudentAccount) onRegister;
  final Function(StudentAccount) onLogin;

  const AuthScreen({
    super.key,
    required this.accounts,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final matricController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isSignup = false;
  bool acceptedDeclaration = false;
  bool showPassword = false;
  String category = 'KRP Student';
  String message = '';

  final Color primaryGreen = const Color(0xFF103B2B);
  final Color accentLime = const Color(0xFFD2F865);

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

  void submit() {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (isSignup) {
      if (!acceptedDeclaration) {
        setState(() {
          message = 'Please accept the student declaration.';
        });
        return;
      }

      final exists = widget.accounts.any((account) => account.email == email);

      if (exists) {
        setState(() {
          message = 'This email is already registered.';
        });
        return;
      }

      if (password != confirmController.text) {
        setState(() {
          message = 'Passwords do not match.';
        });
        return;
      }

      final account = StudentAccount(
        fullName: nameController.text.trim(),
        email: email,
        contact: contactController.text.trim(),
        matric: matricController.text.trim(),
        category: category,
        password: password,
      );

      widget.onRegister(account);
    } else {
      StudentAccount? account;

      for (final item in widget.accounts) {
        if (item.email == email && item.password == password) {
          account = item;
          break;
        }
      }

      if (account == null) {
        setState(() {
          message = 'Account not found. Please check your details.';
        });
        return;
      }

      widget.onLogin(account);
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE9EFEA)),
              ),
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
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F6C8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.sports_tennis,
                            size: 32,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'KRP PLAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'SPORTS HUB · UTM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          letterSpacing: 2.5,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isSignup ? 'Create your account' : 'Welcome back',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSignup
                            ? 'Register to book KRP sports facilities.'
                            : 'Sign in to continue to KRP PLAY.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      if (isSignup) ...[
                        _field(
                          nameController,
                          'Full name',
                          Icons.person_outline,
                        ),
                        _field(
                          contactController,
                          'Contact number',
                          Icons.phone_outlined,
                        ),
                        _field(
                          matricController,
                          'Matric number',
                          Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Student category',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'KRP Student',
                              child: Text('KRP Student'),
                            ),
                            DropdownMenuItem(
                              value: 'Non-KRP Student / Other College',
                              child: Text('Non-KRP Student / Other College'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => category = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _field(
                        emailController,
                        'Email address',
                        Icons.email_outlined,
                        email: true,
                      ),
                      _field(
                        passwordController,
                        'Password',
                        Icons.lock_outline,
                        obscure: !showPassword,
                      ),
                      if (isSignup) ...[
                        _field(
                          confirmController,
                          'Confirm password',
                          Icons.lock_outline,
                          obscure: true,
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: acceptedDeclaration,
                          onChanged: (value) {
                            setState(() {
                              acceptedDeclaration = value ?? false;
                            });
                          },
                          title: const Text(
                            'I confirm that my selected student category and information are accurate. I understand that KRP management may verify my eligibility.',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                      if (!isSignup)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() => showPassword = !showPassword);
                            },
                            child: Text(
                              showPassword ? 'Hide password' : 'Show password',
                              style: TextStyle(color: primaryGreen),
                            ),
                          ),
                        ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: submit,
                        child: Text(
                          isSignup ? 'Create account' : 'Sign in',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignup = !isSignup;
                            message = '';
                          });
                        },
                        child: Text(
                          isSignup
                              ? 'Already have an account? Sign in'
                              : 'New user? Create an account',
                          style: TextStyle(color: primaryGreen),
                        ),
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

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool email = false,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (email && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          if (label == 'Password' && value.length < 8) {
            return 'Use at least 8 characters';
          }
          return null;
        },
      ),
    );
  }
}

