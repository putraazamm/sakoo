import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakoo/screens/welcome_screen.dart';
// import 'package:sakoo/screens/parent/parent_dashboard_page.dart';

void main() async {

  await Supabase.initialize(
    url:'https://cmxbsipjxbcqyojqibng.supabase.co',
    publishableKey: 'sb_publishable_5YeeYAG-ln5QlPQj3JaF0Q_3AqySsrr',
  );

  runApp(const SakooApp());
}

class SakooApp extends StatelessWidget {
  const SakooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sakoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Rounded',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}
