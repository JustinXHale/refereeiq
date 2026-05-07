import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Chat events
  static Future<void> logChatSent({
    required String queryType,
    int? messageCount,
  }) async {
    await _analytics.logEvent(
      name: 'chat_sent',
      parameters: {
        'query_type': queryType,
        if (messageCount != null) 'message_count': messageCount,
      },
    );
  }

  // Incident events
  static Future<void> logIncidentAnalyzed({
    required bool hadClarifications,
  }) async {
    await _analytics.logEvent(
      name: 'incident_analyzed',
      parameters: {
        'had_clarifications': hadClarifications,
      },
    );
  }

  static Future<void> logIncidentRuling({
    required int lawRefsCount,
  }) async {
    await _analytics.logEvent(
      name: 'incident_ruling_received',
      parameters: {
        'law_refs_count': lawRefsCount,
      },
    );
  }

  // Query history events
  static Future<void> logQueryHistoryViewed() async {
    await _analytics.logEvent(name: 'query_history_viewed');
  }

  static Future<void> logQueryHistoryDeleted({
    required int count,
  }) async {
    await _analytics.logEvent(
      name: 'query_history_deleted',
      parameters: {'count': count},
    );
  }

  // Settings events
  static Future<void> logSettingsOpened() async {
    await _analytics.logEvent(name: 'settings_opened');
  }
}
