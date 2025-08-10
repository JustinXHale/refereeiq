import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'conversation_detail_screen.dart';

class FavoritesTab extends StatelessWidget {
  final List<List<Map<String, dynamic>>> favorites;
  final Function(int) onToggleFavorite;

  const FavoritesTab({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to top
            children: [
              const SizedBox(height: 80), // Push down from top
              Icon(
                Icons.star_border,
                size: 64,
                color: const Color(0xFFFADC44), // App yellow
              ),
              const SizedBox(height: 16),
              Text(
                'No favorites yet',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the star icon next to a chat message to save it here for quick access.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = favorites[index];
        final previewText = conversation.isNotEmpty
            ? conversation.first['text'] as String
            : 'Conversation ${index + 1}';
        final timestamp = conversation.isNotEmpty
            ? DateFormat('MMM d, h:mm a')
            .format(conversation.first['timestamp'])
            : '';

        return ListTile(
          leading: IconButton(
            icon: const Icon(Icons.star, color: Color(0xFFFADC44)),
            onPressed: () => onToggleFavorite(index),
            tooltip: 'Remove from favorites',
          ),
          title: Text(
            previewText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(),
          ),
          subtitle: Text(
            timestamp,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ConversationDetailScreen(conversation: conversation),
              ),
            );
          },
        );
      },
    );
  }
}
