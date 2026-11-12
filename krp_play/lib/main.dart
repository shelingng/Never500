import 'package:flutter/material.dart';
import 'package:krp_play/screens/admin/admin_dashboard.dart';
import 'models/student_account.dart';
import 'screens/login_screen.dart';
import 'screens/facility_info_screen.dart';

void main() {
  runApp(const KrpPlayApp());
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

    accounts.add(
      const StudentAccount(
        fullName: 'System Admin',
        email: 'admin@gmail.com',  // 测试用的管理员账号
        contact: '000000000',
        matric: 'ADMIN',
        category: 'Admin',         // 权限标识
        password: 'admin123',         // 测试用的管理员密码
      ),
    );

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
          : (currentAccount!.category == 'Admin'
              ? AdminHomeScreen(onLogout: logout) // 去管理员页面
              : FacilityInfoScreen(               // 去学生主页
                  category: currentAccount!.category,
                  email: currentAccount!.email,
                  studentName: currentAccount!.fullName,
                  contact: currentAccount!.contact,
                  matric: currentAccount!.matric,
                  onLogout: logout,
                )),
    );
  }
}
