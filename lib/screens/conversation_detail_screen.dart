// conversation_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ConversationDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> conversation;

  const ConversationDetailScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversation',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversation.length,
              itemBuilder: (context, index) {
                final message = conversation[index];
                final isUser = message['sender'] == 'user';
                final timestamp = DateFormat('h:mm a').format(message['timestamp']);

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? colorScheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'],
                          style: GoogleFonts.inter(
                            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timestamp,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: (isUser ? colorScheme.onPrimary : colorScheme.onSurface).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: GestureDetector(
              onTap: () {
                // TODO: Restore the conversation — implement this as needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation restored!')),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text(
                    'Restore Conversation',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
