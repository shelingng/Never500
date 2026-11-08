import 'package:flutter/material.dart';

import 'models/student_account.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const KrpPlayApp());
}

class KrpPlayApp extends StatefulWidget {
  const KrpPlayApp({super.key});

  @override
  State<KrpPlayApp> createState() => _KrpPlayAppState();
}

class _KrpPlayAppState extends State<KrpPlayApp> {
  final List<StudentAccount> accounts = [];
  StudentAccount? currentAccount;

  void register(StudentAccount account) {
    setState(() {
      accounts.add(account);
      currentAccount = account;
    });
  }

  void login(StudentAccount account) {
    setState(() {
      currentAccount = account;
    });
  }

  void logout() {
    setState(() {
      currentAccount = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KRP PLAY',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173F32)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: currentAccount == null
          ? AuthScreen(accounts: accounts, onRegister: register, onLogin: login)
          : HomeScreen(account: currentAccount!, onLogout: logout),
    );
  }
}

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.sports_tennis,
                        size: 48,
                        color: Color(0xFF173F32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'KRP PLAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF173F32),
                        ),
                      ),
                      const Text(
                        'SPORTS HUB',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          letterSpacing: 3,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        isSignup ? 'Create your account' : 'Welcome back',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSignup
                            ? 'Register to book KRP sports facilities.'
                            : 'Sign in to continue to KRP PLAY.',
                        style: const TextStyle(color: Colors.grey),
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
                            'I confirm that my selected student category '
                            'and information are accurate. I understand '
                            'that KRP management may verify my eligibility.',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],

                      if (!isSignup)
                        TextButton(
                          onPressed: () {
                            setState(() => showPassword = !showPassword);
                          },
                          child: Text(
                            showPassword ? 'Hide password' : 'Show password',
                          ),
                        ),

                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF173F32),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: submit,
                        child: Text(isSignup ? 'Create account' : 'Sign in'),
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
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
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
