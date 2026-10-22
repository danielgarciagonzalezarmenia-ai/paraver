import 'package:flutter/cupertino.dart';

import '../../core/sports.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/playback_target.dart';
import '../../state/app_state.dart';
import '../../utils/time_utils.dart';
import '../navigation.dart';
import 'common.dart';
import 'sport_artwork.dart';

class FavoriteStar extends StatelessWidget {
  const FavoriteStar({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 18,
  });

  final bool active;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          active ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: size,
          color: active ? p.amber : p.textMuted,
        ),
      ),
    );
  }
}

class EventListCard extends StatelessWidget {
  const EventListCard({super.key, required this.event, this.showDay = false});

  final SportEvent event;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.app;
    final style = sportStyleFor(event.category);
    final live = event.isLiveNow;
    final favorite = app.isEventFavorite(event);

    return PressableScale(
      onTap: () => openPlayer(context, PlaybackTarget.fromEvent(event)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatTime(event.startsAt),
                    style: AppText.mono(
                      18,
                      weight: 700,
                      color: live ? p.coral : p.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    live
                        ? 'EN VIVO'
                        : showDay
                        ? formatDayLabel(event.startsAt).toUpperCase()
                        : formatCountdown(event.startsAt).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      7.5,
                      weight: 700,
                      color: live ? p.coral : p.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 11),
              color: p.border,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SportBadge(
                        icon: style.icon,
                        colors: style.colors,
                        size: 24,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          style.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            8.5,
                            weight: 700,
                            color: p.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      FavoriteStar(
                        active: favorite,
                        onTap: () => app.toggleEventFavorite(event),
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        13.5,
                        weight: 600,
                        color: p.text,
                        height: 1.28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Pill(
                          label: event.channels.first.name,
                          icon: CupertinoIcons.play_circle_fill,
                          color: p.textMuted,
                        ),
                      ),
                      if (event.channels.length > 1) ...[
                        const SizedBox(width: 5),
                        Pill(
                          label: '+${event.channels.length - 1}',
                          color: p.textMuted,
                        ),
                      ],
                      const Spacer(),
                      if (event.isPpv)
                        Text(
                          'PPV',
                          style: AppText.body(
                            8,
                            weight: 800,
                            color: p.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventMiniCard extends StatelessWidget {
  const EventMiniCard({super.key, required this.event});

  final SportEvent event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = sportStyleFor(event.category);
    final live = event.isLiveNow;
    return PressableScale(
      onTap: () => openPlayer(context, PlaybackTarget.fromEvent(event)),
      child: Container(
        width: 262,
        height: 164,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: p.isDark ? p.border : const Color(0x22000000),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: SportArtwork(
            style: style,
            seed: event.id.hashCode,
            iconSize: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x22000000),
                        const Color(0x00000000),
                        const Color(0xD9080D14),
                      ],
                      stops: const [0, 0.35, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (live)
                            const LivePill(compact: true, pulse: false)
                          else
                            Pill(
                              label: formatTime(event.startsAt),
                              color: const Color(0xFFFFFFFF),
                              background: const Color(0x33000000),
                              border: const Color(0x26FFFFFF),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x33000000),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x24FFFFFF),
                              ),
                            ),
                            child: Text(
                              style.label.toUpperCase(),
                              style: AppText.body(
                                8,
                                weight: 700,
                                color: const Color(0xFFFFFFFF),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          17,
                          weight: 700,
                          color: const Color(0xFFFFFFFF),
                          height: 1.08,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 16,
                            color: Color(0xFFD7FF3E),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${event.channels.first.name} · ${formatShortDate(event.startsAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                10,
                                weight: 500,
                                color: const Color(0xB3FFFFFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.item});

  final FeaturedItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = PlaybackTarget.fromFeatured(item);
    return PressableScale(
      onTap: item.channelId == null ? null : () => openPlayer(context, target),
      child: SizedBox(
        width: 214,
        height: 138,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border),
            color: p.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF16212F),
                      child: Icon(
                        CupertinoIcons.sportscourt,
                        color: Color(0x33FFFFFF),
                        size: 56,
                      ),
                    ),
                  )
                else
                  const ColoredBox(color: Color(0xFF16212F)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xE6080D14)],
                      stops: [0.25, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DESTACADO',
                          style: AppText.body(
                            7.5,
                            weight: 800,
                            color: p.onAccent,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          12,
                          weight: 600,
                          color: const Color(0xFFFFFFFF),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChannelTile extends StatelessWidget {
  const ChannelTile({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.app;
    final favorite = app.isChannelFavorite(channel);
    final hue = channel.hue.toDouble();
    final base = HSLColor.fromAHSL(
      1,
      hue,
      p.isDark ? 0.72 : 0.62,
      p.isDark ? 0.26 : 0.42,
    ).toColor();
    final dark = HSLColor.fromAHSL(
      1,
      (hue + 24) % 360,
      0.7,
      p.isDark ? 0.13 : 0.24,
    ).toColor();

    return PressableScale(
      onTap: () => openPlayer(context, PlaybackTarget.fromChannel(channel)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, dark],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: p.isDark ? p.border : const Color(0x1A000000),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -18,
              child: Text(
                channel.initials,
                style: AppText.display(
                  64,
                  weight: 700,
                  color: const Color(0x22FFFFFF),
                  letterSpacing: -2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33000000),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '24/7',
                          style: AppText.body(
                            7.5,
                            weight: 800,
                            color: const Color(0xE6FFFFFF),
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FavoriteStar(
                        active: favorite,
                        onTap: () => app.toggleChannelFavorite(channel),
                        size: 15,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    channel.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      12.5,
                      weight: 700,
                      color: const Color(0xFFFFFFFF),
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
