import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

// User Profile and Account actions screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'User';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Load user profile details from local storage
  void _loadUserInfo() async {
    final name = await ApiService.getUserName();
    final email = await ApiService.getUserEmail();
    setState(() {
      if (name != null && name.isNotEmpty) _name = name;
      if (email != null && email.isNotEmpty) _email = email;
    });
  }

  // Delete all conversations from backend
  void _clearAllChats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Chats', style: TextStyle(color: Color(0xFF292638), fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete all conversations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF89869A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteAllChats();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All chat history deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete chats')),
      );
    }
  }

  // Clear local storage and log out
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: Color(0xFF292638), fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of ChatBuddy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF89869A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B72D9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.clearAuth();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF292638),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar and Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E0FA), width: 1),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFE8E0FA),
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B72D9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(
                      color: Color(0xFF292638),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email.isNotEmpty ? _email : 'user@example.com',
                    style: const TextStyle(
                      color: Color(0xFF89869A),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App & Theme Settings Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E0FA), width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E0FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: Color(0xFF8B72D9),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'App Theme',
                      style: TextStyle(
                        color: Color(0xFF292638),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'ChatBuddy Purple & Light',
                      style: TextStyle(color: Color(0xFF89869A), fontSize: 13),
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E0FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF8B72D9),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'ChatBuddy Version',
                      style: TextStyle(
                        color: Color(0xFF292638),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      '1.0.0 (FastAPI + Groq)',
                      style: TextStyle(color: Color(0xFF89869A), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E0FA), width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Clear All Chat History',
                      style: TextStyle(
                        color: Color(0xFF292638),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Delete all saved conversations from backend',
                      style: TextStyle(color: Color(0xFF89869A), fontSize: 13),
                    ),
                    onTap: _clearAllChats,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E0FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFF8B72D9),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFF8B72D9),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Sign out from this device',
                      style: TextStyle(color: Color(0xFF89869A), fontSize: 13),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
