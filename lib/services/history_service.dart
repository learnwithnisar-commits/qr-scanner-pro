import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record.dart';

/// Persists scan/generated history + favorites using SharedPreferences.
class HistoryService extends ChangeNotifier {
  static const _key = 'qr_history_v1';
  final List<ScanRecord> _items = [];

  List<ScanRecord> get items => List.unmodifiable(_items);

  List<ScanRecord> get favorites => _items.where((e) => e.isFavorite).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    _items
      ..clear()
      ..addAll(raw.map(ScanRecord.fromJsonString));
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, _items.map((e) => e.toJsonString()).toList());
  }

  Future<void> add(ScanRecord record) async {
    // Avoid exact-duplicate spam: bump existing identical scan to the top.
    final dup = _items.indexWhere(
        (e) => e.content == record.content && !e.isGenerated);
    if (dup >= 0 && !record.isGenerated) {
      final existing = _items.removeAt(dup);
      _items.insert(
          0,
          ScanRecord(
            id: existing.id,
            content: existing.content,
            type: existing.type,
            timestamp: record.timestamp,
            isFavorite: existing.isFavorite,
          ));
    } else {
      _items.insert(0, record);
    }
    if (_items.length > 500) _items.removeRange(500, _items.length);
    await _save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(isFavorite: !_items[i].isFavorite);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
    notifyListeners();
  }
}
