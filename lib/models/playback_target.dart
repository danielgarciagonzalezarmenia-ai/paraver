import 'models.dart';

class PlaybackTarget {
  const PlaybackTarget({
    required this.title,
    required this.sources,
    this.subtitle,
    this.category,
    this.startsAt,
    this.imageUrl,
    this.isLive = false,
  });

  final String title;
  final String? subtitle;
  final String? category;
  final DateTime? startsAt;
  final List<ChannelRef> sources;
  final String? imageUrl;
  final bool isLive;

  factory PlaybackTarget.fromEvent(SportEvent event) => PlaybackTarget(
    title: event.title,
    subtitle: event.channels.length > 1
        ? '${event.channels.length} fuentes disponibles'
        : event.channels.first.name,
    category: event.category,
    startsAt: event.startsAt,
    sources: event.channels,
    isLive: event.isLiveNow,
  );

  factory PlaybackTarget.fromChannel(Channel channel) => PlaybackTarget(
    title: channel.name,
    subtitle: 'Canal 24/7',
    category: '24/7',
    sources: [ChannelRef(id: channel.id, name: channel.name, badge: '24/7')],
    isLive: true,
  );

  factory PlaybackTarget.fromFeatured(FeaturedItem item) => PlaybackTarget(
    title: item.title,
    subtitle: 'Destacado',
    category: 'PPV',
    imageUrl: item.imageUrl,
    sources: [
      if (item.channelId != null)
        ChannelRef(id: item.channelId!, name: 'Señal principal', badge: 'HD'),
    ],
    isLive: true,
  );

  PlaybackTarget withSource(ChannelRef source) => PlaybackTarget(
    title: title,
    subtitle: subtitle,
    category: category,
    startsAt: startsAt,
    imageUrl: imageUrl,
    isLive: isLive,
    sources: [source],
  );
}
