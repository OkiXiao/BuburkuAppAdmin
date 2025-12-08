import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import semua halaman
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pesanan_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WAJIB → Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BuburApp());
}

class BuburApp extends StatelessWidget {
  const BuburApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuburKu Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreenBuburKu(),


      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginScreenBuburKu(),
        '/dashboard': (context) => const DashboardScreen(),
        '/pesanan': (context) => const PesananScreen(),
        '/menu': (context) => const MenuScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
