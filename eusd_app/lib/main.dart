import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/card_provider.dart';
import 'services/api_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/card_management_page.dart';
import 'pages/recharge_page.dart';
import 'pages/support_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const EusdApp());
}

class EusdApp extends StatelessWidget {
  const EusdApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CardProvider())],
      child: MaterialApp(
        title: '鑫汇Pay',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const _Splash(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const green = Color(0xFF00C853);
    const bg = Color(0xFF0A0A0A);
    const surface = Color(0xFF141414);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: green,
      colorScheme: const ColorScheme.dark(
        primary: green, secondary: green, surface: surface, background: bg),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0,
        centerTitle: false, scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18,
          fontWeight: FontWeight.w600, letterSpacing: 0.2),
        iconTheme: IconThemeData(color: Colors.white)),
      cardTheme: CardThemeData(color: surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      dividerTheme: const DividerThemeData(color: Color(0xFF1F1F1F), thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: green, unselectedItemColor: Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 1.2)),
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green, foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: green,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), _checkLogin);
  }

  void _checkLogin() {
    if (!mounted) return;
    if (ApiService.isLoggedIn) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const MainScaffold()));
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Logo(),
            SizedBox(height: 24),
            SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF00C853), strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF00C853), shape: BoxShape.circle),
          child: const Center(
            child: Text('e', style: TextStyle(
              color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('鑫汇Pay', style: TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;
  final _pages = const [
    HomePage(),
    CardManagementPage(),
    RechargePage(),
    SupportPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1F1F1F), width: 1))),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card), label: '卡片'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle), label: '充值'),
            BottomNavigationBarItem(icon: Icon(Icons.headset_mic_outlined),
              activeIcon: Icon(Icons.headset_mic), label: '客服'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person), label: '我的'),
          ],
        ),
      ),
    );
  }
}
