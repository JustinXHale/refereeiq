import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class OpenAIService {
  static const String _functionUrl =
      'https://chatwithgpt-s6ub2qfhfq-uc.a.run.app'; // PROD

  static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    // Send ONLY user/assistant turns; server sets the system prompt.
    final openaiMessages = messages.map((msg) {
      final role = (msg['sender'] == 'sofia') ? 'assistant' : 'user';
      return {'role': role, 'content': (msg['text'] ?? '').toString()};
    }).toList();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'Please sign in to continue.';
      }
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'messages': openaiMessages}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['reply'] ?? '').toString().trim();
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
