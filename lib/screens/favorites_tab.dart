import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FavoritesTab extends StatelessWidget {
  final List<List<Map<String, dynamic>>> favorites;
  final void Function(int) onToggleFavorite;

  const FavoritesTab({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Text(
          'No favorites yet.',
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final conversation = favorites[index];
        final firstMessage =
        conversation.isNotEmpty ? conversation.first['text'] : '';
        final timestamp = conversation.isNotEmpty
            ? DateFormat('MMM d, h:mm a').format(conversation.first['timestamp'])
            : '';

        return ListTile(
          leading: IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            tooltip: 'Remove favorite',
            onPressed: () => onToggleFavorite(index),
          ),
          title: Text(
            firstMessage,
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
          onTap: () {
            // TODO: Navigate to Conversation Detail screen
          },
        );
      },
    );
  }
}
