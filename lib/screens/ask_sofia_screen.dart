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

class _AskSofiaScreenState extends State<AskSofiaScreen> {
  final List<List<Map<String, dynamic>>> _savedConversations = [];

  void _handleSaveConversation(List<Map<String, dynamic>> conversation) {
    if (conversation.isNotEmpty) {
      setState(() {
        _savedConversations.insert(0, List.from(conversation)); // newest on top
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation saved!')),
      );
    }
  }

  void _handleToggleFavorite(int index) {
    setState(() {
      _savedConversations.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation removed from favorites.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: colorScheme.primary,
            child: Container(
              color: colorScheme.primary,
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(0),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Chat'),
                  Tab(text: 'Favorites'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ChatTab(
                  onSaveConversation: _handleSaveConversation,
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
