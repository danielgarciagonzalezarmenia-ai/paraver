import 'package:flutter/cupertino.dart';

import '../../core/sports.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/playback_target.dart';
import '../../utils/time_utils.dart';
import '../navigation.dart';
import 'common.dart';
import 'sport_artwork.dart';

class HeroEventCard extends StatelessWidget {
  const HeroEventCard({super.key, required this.event});

  final SportEvent event;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = sportStyleFor(event.category);
    final live = event.isLiveNow;
    final started = event.hasStarted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PressableScale(
        onTap: () => openPlayer(context, PlaybackTarget.fromEvent(event)),
        scale: 0.985,
        child: Container(
          height: 276,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: style.colors.last.withValues(alpha: 0.28),
                blurRadius: 42,
                offset: const Offset(0, 18),
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SportArtwork(
              style: style,
              seed: event.id.hashCode,
              iconSize: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x1A000000),
                          Color(0x00070B12),
                          Color(0xF2070B12),
                        ],
                        stops: [0, 0.34, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (live)
                              const LivePill()
                            else
                              Pill(
                                label: started
                                    ? 'RECIÉN TERMINADO'
                                    : formatCountdown(event.startsAt),
                                color: const Color(0xFFFFFFFF),
                                background: const Color(0x33000000),
                                border: const Color(0x26FFFFFF),
                                icon: CupertinoIcons.clock,
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33000000),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0x24FFFFFF),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    style.icon,
                                    size: 12,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    style.label.toUpperCase(),
                                    style: AppText.body(
                                      8.5,
                                      weight: 700,
                                      color: const Color(0xFFFFFFFF),
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          event.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(
                            27,
                            weight: 700,
                            color: const Color(0xFFFFFFFF),
                            height: 1.06,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formatTime(event.startsAt)} · ${formatDayLabel(event.startsAt)}',
                                    style: AppText.mono(
                                      12,
                                      weight: 600,
                                      color: const Color(0xE6FFFFFF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${event.channels.first.name}${event.channels.length > 1 ? ' · +${event.channels.length - 1} fuentes' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      10,
                                      color: const Color(0xA6FFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: p.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: p.accent.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                live
                                    ? CupertinoIcons.play_fill
                                    : CupertinoIcons.play_fill,
                                size: 23,
                                color: p.onAccent,
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
      ),
    );
  }
}

class HeroFallback extends StatelessWidget {
  const HeroFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: p.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 44),
              const SizedBox(height: 12),
              Text(
                'Preparando la cartelera',
                style: AppText.display(18, weight: 700, color: p.text),
              ),
              const SizedBox(height: 4),
              Text(
                'En unos segundos verás los eventos del día.',
                style: AppText.body(11.5, color: p.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
