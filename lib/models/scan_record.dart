import 'dart:convert';

/// One scanned or generated QR record.
class ScanRecord {
  final String id;
  final String content;
  final String type; // url | text | wifi | contact | generated
  final DateTime timestamp;
  final bool isFavorite;
  final bool isGenerated;

  ScanRecord({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isFavorite = false,
    this.isGenerated = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'isFavorite': isFavorite,
        'isGenerated': isGenerated,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> j) => ScanRecord(
        id: j['id'] as String,
        content: j['content'] as String,
        type: j['type'] as String? ?? 'text',
        timestamp: DateTime.parse(j['timestamp'] as String),
        isFavorite: j['isFavorite'] as bool? ?? false,
        isGenerated: j['isGenerated'] as bool? ?? false,
      );

  ScanRecord copyWith({bool? isFavorite}) => ScanRecord(
        id: id,
        content: content,
        type: type,
        timestamp: timestamp,
        isFavorite: isFavorite ?? this.isFavorite,
        isGenerated: isGenerated,
      );

  /// Classify raw scanned text into a smart type.
  static String classify(String raw) {
    final t = raw.trim();
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.')) {
      return 'url';
    }
    if (t.startsWith('WIFI:')) return 'wifi';
    if (t.startsWith('BEGIN:VCARD')) return 'contact';
    if (lower.startsWith('mailto:') ||
        lower.startsWith('tel:') ||
        lower.startsWith('smsto:')) {
      return 'url';
    }
    return 'text';
  }

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${(DateTime.now().millisecond)}';

  String toJsonString() => jsonEncode(toJson());

  static ScanRecord fromJsonString(String s) =>
      ScanRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
