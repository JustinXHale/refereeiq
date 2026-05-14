import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class OpenAIService {
  static const String _functionUrl =
      'https://chatwithgpt-s6ub2qfhfq-uc.a.run.app'; // PROD
  static const String _incidentAnalyzeUrl =
      'https://incidentanalyze-s6ub2qfhfq-uc.a.run.app';
  static const String _incidentRulingUrl =
      'https://incidentruling-s6ub2qfhfq-uc.a.run.app';
  static const String _lawsSearchUrl =
      'https://lawssearch-s6ub2qfhfq-uc.a.run.app';

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
      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'messages': openaiMessages}),
          )
          .timeout(const Duration(seconds: 115));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = (data['reply'] ?? '').toString().trim();
        if (reply.isEmpty) {
          return 'Sofia returned an empty reply. Try again or shorten your message.';
        }
        return reply;
      } else {
        if (kDebugMode) print('Cloud Function error: ${response.statusCode} ${response.body}');
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['error'] != null) {
            return data['error'].toString();
          }
        } catch (_) {}
        return 'Sorry, something went wrong.';
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) print('Cloud Function exception: $e');
      return 'That took too long and timed out. Try a shorter question or try again.';
    } catch (e) {
      if (kDebugMode) print('Cloud Function exception: $e');
      return 'Sorry, I couldn\'t reach the server.';
    }
  }

  static Future<Map<String, dynamic>> analyzeIncident(String incidentText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'error': 'Please sign in to continue.'};
    }

    final idToken = await user.getIdToken();

    try {
      final response = await http.post(
        Uri.parse(_incidentAnalyzeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'incident': incidentText}),
      );

      if (kDebugMode) print('[incidentAnalyze] url=$_incidentAnalyzeUrl status=${response.statusCode}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return data;
      }
      return {
        'error': 'Incident analysis failed.',
        'status': response.statusCode,
        'body': data,
      };
    } catch (e) {
      return {'error': 'Incident analysis failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getIncidentRuling(
    String incidentText,
    Map<String, String> answersById, {
    String followUp = '',
    List<Map<String, String>>? context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'error': 'Please sign in to continue.'};
    }

    final idToken = await user.getIdToken();

    try {
      final response = await http.post(
        Uri.parse(_incidentRulingUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'incident': incidentText,
          'answers': answersById,
          if (followUp.trim().isNotEmpty) 'followUp': followUp,
          if (context != null && context.isNotEmpty) 'context': context,
        }),
      );

      if (kDebugMode) print('[incidentRuling] url=$_incidentRulingUrl status=${response.statusCode}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return data;
      }
      return {
        'error': 'Incident assessment failed.',
        'status': response.statusCode,
        'body': data,
      };
    } catch (e) {
      return {'error': 'Incident assessment failed: $e'};
    }
  }

  static Future<Map<String, dynamic>?> searchLawRef(String lawRef) async {
    final query = lawRef.trim();
    if (query.isEmpty) return null;

    try {
      final uri = Uri.parse(_lawsSearchUrl).replace(
        queryParameters: {'q': 'Law $query', 'version': '2025.0'},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final results = data is Map<String, dynamic> ? data['results'] as List? : null;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map?;
      if (first == null) return null;
      return Map<String, dynamic>.from(first);
    } catch (_) {
      return null;
    }
  }
}
