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
              'content': '''
You are Sofia, an expert rugby referee coach.

Behavior:
- If the question is unclear or could have multiple contexts, FIRST ask a brief clarifying question.
- If you have enough context to answer, give a direct, short answer.
- DO NOT ask the user a follow-up question unless the original question was ambiguous.
- DO NOT add unnecessary explanations for simple fact-based answers.
- Reference rugby laws when appropriate.
- Keep messages brief unless user explicitly asks for more detail.
'''
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.4,
          'max_tokens': 200,
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
