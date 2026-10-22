import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

enum ThemeChoice { system, dark, light }

class FavoriteEntry {
  const FavoriteEntry({
    required this.type,
    required this.id,
    required this.addedAt,
    this.event,
    this.channel,
  });

  final String type;
  final String id;
  final DateTime addedAt;
  final SportEvent? event;
  final Channel? channel;

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'addedAt': addedAt.toIso8601String(),
    if (event != null) 'event': event!.toJson(),
    if (channel != null) 'channel': channel!.toJson(),
  };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) => FavoriteEntry(
    type: json['type'] as String,
    id: json['id'] as String,
    addedAt: DateTime.parse(json['addedAt'] as String),
    event: json['event'] == null
        ? null
        : SportEvent.fromJson(json['event'] as Map<String, dynamic>),
    channel: json['channel'] == null
        ? null
        : Channel.fromJson(json['channel'] as Map<String, dynamic>),
  );
}

class LocalStore {
  LocalStore(this._prefs);

  static const _scheduleKey = 'cache.schedule.v1';
  static const _themeKey = 'settings.theme';
  static const _favoritesKey = 'favorites.v1';
  static const _lastSyncKey = 'cache.lastSync';

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  ThemeChoice readTheme() {
    switch (_prefs.getString(_themeKey)) {
      case 'dark':
        return ThemeChoice.dark;
      case 'light':
        return ThemeChoice.light;
      default:
        return ThemeChoice.system;
    }
  }

  Future<void> writeTheme(ThemeChoice choice) =>
      _prefs.setString(_themeKey, choice.name);

  ScheduleSnapshot? readSchedule() {
    final raw = _prefs.getString(_scheduleKey);
    if (raw == null) return null;
    try {
      return ScheduleSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSchedule(ScheduleSnapshot snapshot) async {
    await _prefs.setString(_scheduleKey, jsonEncode(snapshot.toJson()));
    await _prefs.setString(_lastSyncKey, snapshot.fetchedAt.toIso8601String());
  }

  DateTime? readLastSync() {
    final raw = _prefs.getString(_lastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  List<FavoriteEntry> readFavorites() {
    final raw = _prefs.getString(_favoritesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FavoriteEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeFavorites(List<FavoriteEntry> favorites) =>
      _prefs.setString(
        _favoritesKey,
        jsonEncode(favorites.map((f) => f.toJson()).toList()),
      );

  Future<void> clearCache() async {
    await _prefs.remove(_scheduleKey);
    await _prefs.remove(_lastSyncKey);
  }
}
