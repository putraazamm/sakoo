import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../screens/auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // [Placeholder for top right card]
          Positioned(
            top: -20,
            right: -60,
            child: Transform.rotate(
              angle: math.pi / 4.5,
              child: SvgPicture.asset(
                'lib/assets/images/card.svg',
                height: 200,
              ),
            ),
          ),

          // [Placeholder for bottom left card]
          Positioned(
            top: 450,
            left: -130,
            child: Transform.rotate(
              angle: -math.pi / 4.5,
              child: SvgPicture.asset(
                'lib/assets/images/card.svg',
                height: 200,
              ),
            ),
          ),

          // Hero Text
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 180), // space from top

                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 38,
                        color: Colors.black87,
                        height: 1.2,
                        fontFamily: 'SF Pro Rounded',
                      ),
                      children: [
                        TextSpan(text: "Let's make your child\ngo "),
                        TextSpan(
                          text: "cashless!",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // with Sakoo [Logo]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "with",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.black87,
                          fontFamily: 'SF Pro Rounded',
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'lib/assets/images/sakoo-logo-welcome-screen.svg',
                        height: 30,
                      ),
                    ],
                  ),

                  const Spacer(), // push button to bottom

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // login logic here
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 25, 25, 25),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Color(0xFF252525),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Rounded',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "or",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontFamily: 'SF Pro Rounded',
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () {
                            Get.to(() => LoginScreen());
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text(
                            "Continue with Username/Email",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              fontFamily: 'SF Pro Rounded',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32), // space from bottom
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
