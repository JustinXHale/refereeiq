import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  String _inputText = '';
  bool _isFavorited = false;
  String _lastAIReply = '';

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
      _inputText = '';
      _isThinking = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final aiResponse = 'This is Sofia\'s answer to: "$text"';
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': aiResponse,
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
        _lastAIReply = aiResponse;
        _isFavorited = false;
      });
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final timestamp = DateFormat('h:mm a').format(message['timestamp']);

    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFFDCF8C6) : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message['text'],
              style: GoogleFonts.inter(fontSize: 16),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timestamp,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ask Sofia',
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sofia is thinking...',
                                style: GoogleFonts.inter(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final message = _messages[index];
                  return _buildMessage(message);
                }
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (text) {
                      setState(() {
                        _inputText = text;
                      });
                    },
                    onSubmitted: (text) {
                      _sendMessage();
                    },
                    decoration: InputDecoration(
                      hintText: 'Ask Sofia...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isFavorited
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isFavorited
                              ? colorScheme.primary
                              : Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isFavorited = !_isFavorited;
                          });
                          if (_isFavorited) {
                            print('Favorited message: $_lastAIReply');
                          } else {
                            print('Unfavorited');
                          }
                        },
                        tooltip: _isFavorited ? 'Unsave' : 'Save last AI reply',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _inputText.isNotEmpty
                        ? colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed:
                  _inputText.isNotEmpty ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
