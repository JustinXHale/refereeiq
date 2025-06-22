// ask_sofia_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_tab.dart';
import 'favorites_tab.dart';

class AskSofiaScreen extends StatefulWidget {
  const AskSofiaScreen({super.key});

  @override
  State<AskSofiaScreen> createState() => _AskSofiaScreenState();
}

class _AskSofiaScreenState extends State<AskSofiaScreen>
    with AutomaticKeepAliveClientMixin {
  final List<List<Map<String, dynamic>>> _savedConversations = [];
  final List<Map<String, dynamic>> _currentMessages = [];

  void _handleSaveConversation(List<Map<String, dynamic>> conversation) {
    if (conversation.isNotEmpty) {
      setState(() {
        _savedConversations.insert(0, List.from(conversation));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation saved!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleToggleFavorite(int index) {
    setState(() {
      _savedConversations.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation removed from favorites.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMessagesChanged(List<Map<String, dynamic>> newMessages) {
    setState(() {
      _currentMessages
        ..clear()
        ..addAll(newMessages);
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              const Tab(text: 'Chat'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Favorites'),
                    const SizedBox(width: 4),
                    if (_savedConversations.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _savedConversations.length.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ChatTab(
                  onSaveConversation: _handleSaveConversation,
                  messages: _currentMessages,
                  onMessagesChanged: _handleMessagesChanged,
                ),
                FavoritesTab(
                  favorites: _savedConversations,
                  onToggleFavorite: _handleToggleFavorite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
