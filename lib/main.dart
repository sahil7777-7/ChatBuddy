import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

// App ka entry point
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChatBuddyApp());
}

// Main App Widget jahan app ka theme set hota hai
class ChatBuddyApp extends StatelessWidget {
  const ChatBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Simple light background aur primary color
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        primaryColor: const Color(0xFF8B72D9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B72D9),
          primary: const Color(0xFF8B72D9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF292638)),
        ),
      ),
      // App open hote hi SplashScreen chalega
      home: const SplashScreen(),
    );
  }
}
