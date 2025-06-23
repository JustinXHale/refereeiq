import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // Replace this with your actual Cloud Function URL:
  static const String _functionUrl = 'https://us-central1-refereeiq-69cff.cloudfunctions.net/chatWithGPT';

  static Future<String> sendMessage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': prompt,
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
