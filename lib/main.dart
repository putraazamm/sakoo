import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; 
import 'package:get/get.dart';
import 'package:sakoo/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakoo/screens/welcome_screen.dart';
import 'services/session_service.dart';
import 'screens/parent/parent_main_shell.dart';
import 'screens/merchant/merchant_main_shell.dart';

void main() async {
  // ✅ preserve() FIRST before anything else — keeps splash visible
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: 'https://cmxbsipjxbcqyojqibng.supabase.co',
    publishableKey: 'sb_publishable_5YeeYAG-ln5QlPQj3JaF0Q_3AqySsrr',
  );

  final savedSession = await SessionService.loadSession();

  // ✅ remove() AFTER all async work is done — splash disappears exactly here
  // and the correct screen (shell or welcome) is shown immediately, no flash
  FlutterNativeSplash.remove();

  runApp(SakooApp(initialSession: savedSession));
}

class SakooApp extends StatelessWidget {
  final Map<String, dynamic>? initialSession;
  const SakooApp({super.key, this.initialSession});

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;
    if (initialSession != null) {
      final role = initialSession!['role'];
      if (role == 'parent') {
        homeScreen = const ParentMainShell();
      } else if (role == 'merchant') {
        homeScreen = const MerchantMainShell();
      } else {
        homeScreen = const WelcomeScreen();
      }
    } else {
      homeScreen = const WelcomeScreen();
    }

    return GetMaterialApp(
      title: 'Sakoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Rounded',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: homeScreen,
      getPages: [
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
      ],
    );
  }
}