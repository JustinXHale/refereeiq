import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatTab extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSaveConversation;

  const ChatTab({super.key, required this.onSaveConversation});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
      });
      _isThinking = true;
    });

    _controller.clear();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add({
          'sender': 'sofia',
          'text': 'This is Sofia\'s response to: "$text"',
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
      });
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUser = message['sender'] == 'user';
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? const Color(0xFFFADC44) : Colors.grey.shade200;
    final textColor = Colors.black;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['text'],
              style: GoogleFonts.inter(
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message['timestamp']),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat cleared!')),
    );
  }

  void _saveConversation() {
    if (_messages.isEmpty) return;
    widget.onSaveConversation(_messages);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isThinking && index == _messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(width: 12),
                        Text(
                          'Sofia is thinking...',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final message = _messages[index];
              return _buildMessage(message);
            },
          ),
        ),
        if (_messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _saveConversation,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Save Conversation'),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask Sofia a question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _clearChat,
                      tooltip: 'Clear chat',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                onPressed: _sendMessage,
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
