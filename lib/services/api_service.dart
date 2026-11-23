import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Service handling all backend HTTP calls and local token storage
class ApiService {
  // Use http://localhost:8000 for Chrome / Web / Windows desktop
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://YOUR_PC_IP:8000 for Physical Devices
  static const String baseUrl = 'http://localhost:8000';

  // Save authentication token and user info
  static Future<void> saveAuthData(String token, String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
  }

  // Retrieve stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Retrieve stored user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  // Retrieve stored user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  // Clear authentication data on logout
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // 1. POST /signup - Register a new user
  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Signup failed'};
    }
  }

  // 2. POST /login - Authenticate user and persist credentials
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data['token'];
      final user = data['user'];
      await saveAuthData(token, user['name'] ?? '', user['email'] ?? '');
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Login failed'};
    }
  }

  // 3. POST /chat - Send user prompt and receive AI reply
  static Future<Map<String, dynamic>> sendMessage(String message, {String? chatId}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/chat');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        if (chatId != null) 'chat_id': chatId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['detail'] ?? 'Failed to send message'};
    }
  }

  // 4. GET /chats - Fetch user conversations list
  static Future<List<dynamic>> getChats() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/chats');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chats');
    }
  }

  // 5. GET /chats/{chat_id} - Fetch conversation messages
  static Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/chats/$chatId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat conversation');
    }
  }

  // 6. DELETE /chats/{chat_id} - Delete single conversation
  static Future<bool> deleteChat(String chatId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/chats/$chatId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // 7. DELETE /chats - Delete all conversations
  static Future<bool> deleteAllChats() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/chats');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}
