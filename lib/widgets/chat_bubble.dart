import 'package:flutter/material.dart';

// Chat bubble widget displaying user (right side, purple) and AI (left side, white) messages
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFE8E0FA) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFFE8E0FA), width: 1),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF292638),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                time!,
                style: const TextStyle(
                  color: Color(0xFF89869A),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
