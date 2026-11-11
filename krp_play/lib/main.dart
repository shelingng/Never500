import 'package:flutter/material.dart';
import 'models/student_account.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    const KrpPlayApp(
      // Default test account for developer convenience (Looi Yu Xiang)
      // Pass null to test the sign-in / registration flow
      initialAccount: StudentAccount(
        fullName: 'Looi Yu Xiang',
        email: 'yuxiang@student.utm.my',
        contact: '0123456789',
        matric: 'A24CS0107',
        category: 'KRP Student',
        password: 'devpassword123',
      ),
    ),
  );
}

class KrpPlayApp extends StatefulWidget {
  final StudentAccount? initialAccount;

  const KrpPlayApp({super.key, this.initialAccount});

  @override
  State<KrpPlayApp> createState() => _KrpPlayAppState();
}

class _KrpPlayAppState extends State<KrpPlayApp> {
  final List<StudentAccount> accounts = [];
  StudentAccount? currentAccount;

  @override
  void initState() {
    super.initState();
    if (widget.initialAccount != null) {
      accounts.add(widget.initialAccount!);
      currentAccount = widget.initialAccount;
    }
  }

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF103B2B),
          primary: const Color(0xFF103B2B),
          secondary: const Color(0xFFD2F865),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9F7),
          foregroundColor: Color(0xFF103B2B),
          elevation: 0,
        ),
      ),
      home: currentAccount == null
          ? AuthScreen(accounts: accounts, onRegister: register, onLogin: login)
          : HomeScreen(account: currentAccount!, onLogout: logout),
    );
  }
}
