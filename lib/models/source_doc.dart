// models/source_doc.dart

class SourceDoc {
  final String id;
  final String sourceName;
  final String sourceType; // Global | Program | National | Competition | Local
  final String region;
  final String? competition;
  final String version;
  final DateTime effectiveDate;
  final String status; // Active | Archived
  final String uploadedBy;
  final String documentUrl;
  final List<String> tags;
  final bool defaultForSofia;
  final DateTime lastUpdated;

  SourceDoc({
    required this.id,
    required this.sourceName,
    required this.sourceType,
    required this.region,
    this.competition,
    required this.version,
    required this.effectiveDate,
    required this.status,
    required this.uploadedBy,
    required this.documentUrl,
    required this.tags,
    required this.defaultForSofia,
    required this.lastUpdated,
  });
}
