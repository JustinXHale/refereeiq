import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/openai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _ChatTabState extends State<ChatTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _isThinking = false;

  final List<String> _examplePrompts = const [
    'Explain offside when a player is in front of the kicker.',
    'What happens if the ball hits the referee?',
    'Walk me through Law 19 lineout basics.',
    'Quick throw: when is it still legal?',
    'How do you manage repeated scrum collapses?'
  ];

  String _toVIEW(String input) {
    final re = RegExp(r'\[Link\]\((https?:\/\/[^)]+)\)', caseSensitive: false);
    return input.replaceAllMapped(re, (m) => '[VIEW](${m.group(1)})');
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _prefillAndFocus(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _inputFocus.requestFocus();
  }

  void _sendMessage() async {
    final text = (_controller.text).trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message!')),
      );
      return;
    }

    final updatedMessages = List<Map<String, dynamic>>.from(widget.messages)
      ..add({
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
      });

    widget.onMessagesChanged(updatedMessages);
    _scrollToBottom();

    setState(() {
      _isThinking = true;
    });
    _controller.clear();

    try {
      final responseText = await OpenAIService.sendMessage(updatedMessages);

      final updatedMessagesAfterResponse =
      List<Map<String, dynamic>>.from(updatedMessages)
        ..add({
          'sender': 'sofia',
          'text': responseText,
          'timestamp': DateTime.now(),
        });

      widget.onMessagesChanged(updatedMessagesAfterResponse);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() {
      _isThinking = false;
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final bool isUser = message['sender'] == 'user';
    final String text = (message['text'] ?? '').toString();
    final DateTime ts = (message['timestamp'] is DateTime)
        ? message['timestamp'] as DateTime
        : DateTime.now();

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? const Color(0xFFFADC44) : Colors.grey.shade200;
    const textColor = Colors.black;

    final Widget bubbleChild = isUser
        ? Text(
      text,
      style: GoogleFonts.inter(fontSize: 16, color: textColor),
    )
        : MarkdownBody(
      data: _toVIEW(text),
      onTapLink: (label, href, title) {
        if (href != null) _openLink(href);
      },
      styleSheet:
      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: GoogleFonts.inter(fontSize: 16, color: Colors.black),
        a: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.tertiary,
          decoration: TextDecoration.underline,
        ),
      ),
    );

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
            bubbleChild,
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(ts),
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

  Widget _buildPromptChips(BuildContext context) {
    final maxChipWidth = MediaQuery.of(context).size.width * 0.60;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _examplePrompts.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: GestureDetector(
              onTap: () => _prefillAndFocus(text),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFADC44),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0CF1E), width: 1),
                  ),
                  child: Text(
                    text,
                    softWrap: true,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        children: [
          if (widget.messages.isEmpty && !_isThinking) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/app_icon.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ask Sofia anything!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap a prompt below or type your own.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildPromptChips(context),
          ] else ...[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
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
          ],

          if (widget.messages.isNotEmpty) ...[
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
          ],

          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              left: 12,
              right: 12,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _inputFocus,
                    minLines: 2,
                    maxLines: 5,
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask a question, describe a scenario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
