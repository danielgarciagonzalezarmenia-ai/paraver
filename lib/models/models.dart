import '../utils/hash.dart';

class Channel {
  const Channel({required this.id, required this.name});

  final String id;
  final String name;

  String get initials {
    final words = name
        .replaceAll(RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'PV';
    if (words.length == 1) {
      final w = words.first;
      return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w.toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  int get hue => stableHash('channel:$id:$name') % 360;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Channel.fromJson(Map<String, dynamic> json) =>
      Channel(id: json['id'] as String, name: json['name'] as String);
}

class ChannelRef {
  const ChannelRef({required this.id, required this.name, this.badge = 'HD'});

  final String id;
  final String name;
  final String badge;

  String get label => badge.trim().isEmpty ? name : '$name · $badge';

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'badge': badge};

  factory ChannelRef.fromJson(Map<String, dynamic> json) => ChannelRef(
    id: json['id'] as String,
    name: json['name'] as String,
    badge: (json['badge'] as String?) ?? 'HD',
  );
}

class SportEvent {
  const SportEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.startsAt,
    required this.channels,
    this.isPpv = false,
    this.forcedLive = false,
  });

  final String id;
  final String title;
  final String category;
  final DateTime startsAt;
  final List<ChannelRef> channels;
  final bool isPpv;
  final bool forcedLive;

  bool get isLiveNow {
    if (forcedLive) return true;
    final elapsed = DateTime.now().difference(startsAt);
    return elapsed >= const Duration(minutes: -5) &&
        elapsed <= const Duration(hours: 3);
  }

  bool get hasStarted => DateTime.now().isAfter(startsAt);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'startsAt': startsAt.toIso8601String(),
    'channels': channels.map((c) => c.toJson()).toList(),
    'isPpv': isPpv,
    'forcedLive': forcedLive,
  };

  factory SportEvent.fromJson(Map<String, dynamic> json) => SportEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    channels: (json['channels'] as List<dynamic>)
        .map((e) => ChannelRef.fromJson(e as Map<String, dynamic>))
        .toList(),
    isPpv: (json['isPpv'] as bool?) ?? false,
    forcedLive: (json['forcedLive'] as bool?) ?? false,
  );
}

class FeaturedItem {
  const FeaturedItem({required this.title, this.imageUrl, this.channelId});

  final String title;
  final String? imageUrl;
  final String? channelId;

  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'channelId': channelId,
  };

  factory FeaturedItem.fromJson(Map<String, dynamic> json) => FeaturedItem(
    title: json['title'] as String,
    imageUrl: json['imageUrl'] as String?,
    channelId: json['channelId'] as String?,
  );
}

class ScheduleSnapshot {
  const ScheduleSnapshot({
    required this.events,
    required this.channels,
    required this.featured,
    required this.fetchedAt,
  });

  final List<SportEvent> events;
  final List<Channel> channels;
  final List<FeaturedItem> featured;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
    'channels': channels.map((c) => c.toJson()).toList(),
    'featured': featured.map((f) => f.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory ScheduleSnapshot.fromJson(Map<String, dynamic> json) =>
      ScheduleSnapshot(
        events: (json['events'] as List<dynamic>)
            .map((e) => SportEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        channels: (json['channels'] as List<dynamic>)
            .map((e) => Channel.fromJson(e as Map<String, dynamic>))
            .toList(),
        featured: (json['featured'] as List<dynamic>)
            .map((e) => FeaturedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
}
