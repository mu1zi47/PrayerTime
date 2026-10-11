import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbihCounter extends ChangeNotifier {
  static const storageKey = 'tasbih_counter';
  static Future<void> _pendingWrites = Future.value();
  final SharedPreferences _prefs;
  int _limit;
  int _current;
  int _total;
  Future<void> _saved = Future.value();

  TasbihCounter._(this._prefs, this._limit, this._current, this._total);

  static Future<TasbihCounter> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _pendingWrites;
    var limit = 33;
    var current = 0;
    var total = 0;
    try {
      final raw = jsonDecode(prefs.getString(storageKey) ?? '{}');
      if (raw is Map) {
        if ([0, 33, 99].contains(raw['limit'])) limit = raw['limit'] as int;
        if (raw['total'] is int && raw['total'] >= 0) {
          total = raw['total'] as int;
        }
        if (raw['current'] is int && raw['current'] >= 0) {
          current = raw['current'] as int;
        }
        current = current.clamp(0, total);
        if (limit != 0) current %= limit;
      }
    } catch (_) {
      // A missing or damaged saved counter starts at zero.
    }
    return TasbihCounter._(prefs, limit, current, total);
  }

  int get limit => _limit;
  int get current => _current;
  int get total => _total;
  Future<void> get saved => _saved;

  void increment() {
    _total++;
    _current++;
    if (_limit != 0 && _current >= _limit) _current = 0;
    _save();
  }

  void setLimit(int value) {
    if (![0, 33, 99].contains(value) || value == _limit) return;
    _limit = value;
    _current = 0;
    _save();
  }

  void clear() {
    _current = 0;
    _total = 0;
    _save();
  }

  void _save() {
    final snapshot = jsonEncode({
      'limit': _limit,
      'current': _current,
      'total': _total,
    });
    // Serialize rapid taps and resets so an older write cannot win.
    _saved = _pendingWrites = _pendingWrites.then((_) async {
      await _prefs.setString(storageKey, snapshot);
    });
    notifyListeners();
  }
}
