import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';

// Chat interface screen where user converses with AI
class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? initialTitle;

  const ChatScreen({
    super.key,
    this.chatId,
    this.initialTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _currentChatId;
  String _title = 'New Chat';
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingHistory = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    if (widget.initialTitle != null) {
      _title = widget.initialTitle!;
    }

    if (_currentChatId != null) {
      _loadChatHistory();
    }
  }

  // Load message history from backend for existing conversation
  void _loadChatHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final chatData = await ApiService.getChatMessages(_currentChatId!);
      final List rawMessages = chatData['messages'] ?? [];
      
      setState(() {
        _title = chatData['title'] ?? 'Chat';
        _messages = rawMessages.map((m) => {
          'role': m['role'],
          'content': m['content'],
          'created_at': m['created_at'],
        }).toList();
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load chat history')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  // Send message to Groq AI via backend
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();

    // Show user's message immediately on screen
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final result = await ApiService.sendMessage(text, chatId: _currentChatId);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _currentChatId = data['chat_id'];
          _messages.add({
            'role': 'assistant',
            'content': data['response'],
            'created_at': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to send message')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to backend')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // Clear current messages from screen
  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat', style: TextStyle(color: Color(0xFF292638), fontWeight: FontWeight.bold)),
        content: const Text('Do you want to clear the messages on screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF89869A))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _currentChatId = null;
                _title = 'New Chat';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B72D9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF292638)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF292638),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF89869A)),
            tooltip: 'Clear Conversation',
            onPressed: _messages.isEmpty ? null : _clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B72D9)),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8E0FA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF8B72D9),
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Say hello to ChatBuddy!',
                              style: TextStyle(
                                color: Color(0xFF292638),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ask anything or start a conversation below.',
                              style: TextStyle(
                                color: Color(0xFF89869A),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return ChatBubble(
                            message: msg['content'] ?? '',
                            isUser: isUser,
                          );
                        },
                      ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF8B72D9),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ChatBuddy is typing...',
                    style: TextStyle(
                      color: Color(0xFF89869A),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE8E0FA), width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F7FC),
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF89869A),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B72D9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
