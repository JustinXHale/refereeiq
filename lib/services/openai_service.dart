import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<String> sendMessage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o', // Or whichever model you're testing
          'messages': [
            {
              'role': 'system',
              'content': 'You are Sofia, an expert rugby referee coach. You answer questions clearly and link them to relevant laws and guidelines when possible.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content.trim();
      } else {
        print('OpenAI API error: ${response.statusCode} ${response.body}');
        return 'Sorry, something went wrong.';
      }
    } catch (e) {
      print('OpenAI API exception: $e');
      return 'Sorry, I couldn\'t reach OpenAI.';
    }
  }
}
