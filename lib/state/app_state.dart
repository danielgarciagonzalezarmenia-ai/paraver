import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/sports.dart';
import '../data/dlive_client.dart';
import '../data/embed_document.dart';
import '../data/local_store.dart';
import '../data/stream_resolver.dart';
import '../models/models.dart';
import '../utils/time_utils.dart';

class AppState extends ChangeNotifier {
  AppState({required LocalStore store, required DliveClient client})
    : _store = store,
      _client = client;

  final LocalStore _store;
  final DliveClient _client;

  late final StreamResolver streams = StreamResolver(_client);
  late final EmbedDocument embeds = EmbedDocument(_client);

  ScheduleSnapshot? _snapshot;
  ThemeChoice _themeChoice = ThemeChoice.system;
  List<FavoriteEntry> _favorites = [];
  bool _loading = false;
  String? _error;
  Timer? _clock;

  ScheduleSnapshot? get snapshot => _snapshot;
  ThemeChoice get themeChoice => _themeChoice;
  bool get isLoading => _loading;
  String? get error => _error;
  List<FavoriteEntry> get favorites => List.unmodifiable(_favorites);
  DateTime? get lastSync => _snapshot?.fetchedAt;
  bool get hasData => _snapshot != null;

  List<SportEvent> get events => _snapshot?.events ?? const [];
  List<Channel> get channels => _snapshot?.channels ?? const [];
  List<FeaturedItem> get featured => _snapshot?.featured ?? const [];
  List<FavoriteEntry> get favoriteEvents =>
      _favorites.where((f) => f.type == 'event' && f.event != null).toList();
  List<FavoriteEntry> get favoriteChannels => _favorites
      .where((f) => f.type == 'channel' && f.channel != null)
      .toList();

  List<SportEvent> get liveEvents {
    final list = events.where((e) => e.isLiveNow).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  List<SportEvent> get nextEvents {
    final now = DateTime.now();
    final list = events.where((e) => e.startsAt.isAfter(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  List<SportEvent> eventsForSport(String? sportKey) {
    if (sportKey == null) return events;
    return events
        .where((e) => sportStyleFor(e.category).key == sportKey)
        .toList();
  }

  Map<String, List<SportEvent>> agendaFor(String? sportKey) {
    final grouped = <String, List<SportEvent>>{};
    for (final event in eventsForSport(sportKey)) {
      final key = formatDayLabel(event.startsAt);
      grouped.putIfAbsent(key, () => []).add(event);
    }
    return grouped;
  }

  SportEvent? get heroEvent {
    final live = liveEvents;
    if (live.isNotEmpty) {
      live.sort((a, b) {
        if (a.isPpv != b.isPpv) return a.isPpv ? -1 : 1;
        return a.startsAt.compareTo(b.startsAt);
      });
      return live.first;
    }
    final upcoming = nextEvents;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> bootstrap() async {
    _themeChoice = _store.readTheme();
    _favorites = _store.readFavorites();
    _snapshot = _store.readSchedule();
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 45), (_) {
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> refreshIfNeeded() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      await refresh();
      return;
    }
    final age = DateTime.now().difference(snapshot.fetchedAt);
    if (age > const Duration(minutes: 10)) {
      await refresh();
    }
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _client.fetchSnapshot();
      _snapshot = snapshot;
      await _store.writeSchedule(snapshot);
    } catch (error) {
      _error = error is DliveException
          ? error.message
          : 'No se pudo conectar con la cartelera. Revisa tu conexión.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeChoice choice) async {
    _themeChoice = choice;
    notifyListeners();
    await _store.writeTheme(choice);
  }

  bool isEventFavorite(SportEvent event) =>
      _favorites.any((f) => f.type == 'event' && f.id == event.id);

  bool isChannelFavorite(Channel channel) =>
      _favorites.any((f) => f.type == 'channel' && f.id == channel.id);

  bool isChannelIdFavorite(String id) =>
      _favorites.any((f) => f.type == 'channel' && f.id == id);

  Future<void> toggleEventFavorite(SportEvent event) async {
    final index = _favorites.indexWhere(
      (f) => f.type == 'event' && f.id == event.id,
    );
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(
        0,
        FavoriteEntry(
          type: 'event',
          id: event.id,
          addedAt: DateTime.now(),
          event: event,
        ),
      );
    }
    notifyListeners();
    await _store.writeFavorites(_favorites);
  }

  Future<void> toggleChannelFavorite(Channel channel) async {
    final index = _favorites.indexWhere(
      (f) => f.type == 'channel' && f.id == channel.id,
    );
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(
        0,
        FavoriteEntry(
          type: 'channel',
          id: channel.id,
          addedAt: DateTime.now(),
          channel: channel,
        ),
      );
    }
    notifyListeners();
    await _store.writeFavorites(_favorites);
  }

  ChannelRef? channelRefForId(String id) {
    for (final event in events) {
      for (final channel in event.channels) {
        if (channel.id == id) return channel;
      }
    }
    return null;
  }

  Channel? channelForId(String id) {
    for (final channel in channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }

  Future<void> clearCache() async {
    await _store.clearCache();
    _snapshot = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
}
