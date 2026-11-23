import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Initial screen that checks if the user is already logged in
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Check saved authentication token
  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await ApiService.getToken();

    if (!mounted) return;

    // Navigate to Home if logged in, otherwise go to Login
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8B72D9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            // App Name
            const Text(
              'ChatBuddy',
              style: TextStyle(
                color: Color(0xFF292638),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your friendly AI companion',
              style: TextStyle(
                color: Color(0xFF89869A),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
