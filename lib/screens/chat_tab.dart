// chat_tab.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatTab extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSaveConversation;
  final List<Map<String, dynamic>> messages;
  final Function(List<Map<String, dynamic>>) onMessagesChanged;

  const ChatTab({
    super.key,
    required this.onSaveConversation,
    required this.messages,
    required this.onMessagesChanged,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _controller = TextEditingController();
  bool _isThinking = false;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final updatedMessages = List<Map<String, dynamic>>.from(widget.messages)
      ..add({
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
      });

    widget.onMessagesChanged(updatedMessages);

    setState(() {
      _isThinking = true;
    });

    _controller.clear();

    Future.delayed(const Duration(seconds: 2), () {
      final updatedMessagesAfterResponse =
      List<Map<String, dynamic>>.from(updatedMessages)
        ..add({
          'sender': 'sofia',
          'text': 'This is Sofia\'s response to: "$text"',
          'timestamp': DateTime.now(),
        });

      widget.onMessagesChanged(updatedMessagesAfterResponse);

      setState(() {
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
    widget.onMessagesChanged([]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat cleared!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveConversation() {
    if (widget.messages.isEmpty) return;
    widget.onSaveConversation(widget.messages);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: widget.messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isThinking && index == widget.messages.length) {
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

              final message = widget.messages[index];
              return _buildMessage(message);
            },
          ),
        ),
        if (widget.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _saveConversation,
                  icon: const Icon(Icons.star_border, color: Colors.black),
                  label: Text(
                    'Save Conversation',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _clearChat,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    'Clear Thread',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
