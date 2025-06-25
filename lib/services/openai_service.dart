import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _functionUrl = 'https://us-central1-refereeiq-69cff.cloudfunctions.net/chatWithGPT';

  static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    // Build the list for OpenAI format
    final openaiMessages = [
      {
        'role': 'system',
        'content': 'You are Sofia, an expert rugby referee coach helping users deeply understand rugby laws and decisions. '
            'When a user asks a vague or broad question, first ask clarifying follow-up questions before giving an answer. '
            'Only provide final answers after gathering enough context. '
            'Link your responses to relevant laws or guidelines when possible. '
            'Keep answers short and clear. Only answer questions about rugby union — politely decline unrelated questions.'
      },
      ...messages.map((msg) {
        return {
          'role': msg['sender'] == 'user' ? 'user' : 'assistant',
          'content': msg['text']
        };
      }).toList(),
    ];

    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': openaiMessages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'].toString().trim();
      } else {
        print('Cloud Function error: ${response.statusCode} ${response.body}');
        return 'Sorry, something went wrong.';
      }
    } catch (e) {
      print('Cloud Function exception: $e');
      return 'Sorry, I couldn\'t reach the server.';
    }
  }
}
