import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

// Displays list of previous conversation sessions
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  // Load chats from backend
  void _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chats = await ApiService.getChats();
      if (!mounted) return;
      setState(() {
        _chats = chats;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load conversations';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Delete single conversation
  void _deleteChat(String chatId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Chat', style: TextStyle(color: Color(0xFF292638), fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this conversation?'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteChat(chatId);
    if (!mounted) return;

    if (success) {
      setState(() {
        _chats.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat History',
          style: TextStyle(
            color: Color(0xFF292638),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B72D9)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF89869A)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadChats,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B72D9),
                        ),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No conversation history',
                            style: TextStyle(
                              color: Color(0xFF292638),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your saved chats will appear here.',
                            style: TextStyle(
                              color: Color(0xFF89869A),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF8B72D9),
                      onRefresh: () async => _loadChats(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          final chatId = chat['chat_id'];
                          final title = chat['title'] ?? 'Conversation';
                          final updatedAt = chat['updated_at'] != null
                              ? chat['updated_at'].toString().split('T').first
                              : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE8E0FA),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8E0FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.chat_outlined,
                                  color: Color(0xFF8B72D9),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF292638),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                updatedAt,
                                style: const TextStyle(
                                  color: Color(0xFF89869A),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red.shade300,
                                ),
                                onPressed: () => _deleteChat(chatId, index),
                              ),
                              onTap: () async {
                                final refresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chatId,
                                      initialTitle: title,
                                    ),
                                  ),
                                );
                                if (refresh == true) {
                                  _loadChats();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
