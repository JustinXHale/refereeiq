import 'package:flutter/foundation.dart';

class SourcesSearchBridge {
  static final ValueNotifier<String?> query = ValueNotifier<String?>(null);

  static void setQuery(String value) {
    query.value = value.trim();
  }

  static void clear() {
    query.value = null;
  }
}
