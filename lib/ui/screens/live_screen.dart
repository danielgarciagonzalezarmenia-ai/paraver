import 'package:flutter/cupertino.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../utils/time_utils.dart';
import '../search_screen.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.app;
    final live = app.liveEvents;
    final upcoming = app.nextEvents
        .where((e) => e.startsAt.difference(DateTime.now()).inHours <= 8)
        .take(10)
        .toList();

    return PageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: app.refresh),
          SliverToBoxAdapter(
            child: Column(
              children: [
                ScreenHeader(
                  title: 'En vivo',
                  eyebrow: 'Señal limpia',
                  subtitle: live.isEmpty
                      ? 'Ahora no hay eventos activos'
                      : '${live.length} eventos transmitiendo ahora',
                  trailing: RoundIconButton(
                    icon: CupertinoIcons.search,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const SearchScreen(),
                      ),
                    ),
                  ),
                ),
                if (app.error != null && app.hasData)
                  InlineError(message: app.error!, onRetry: app.refresh),
              ],
            ),
          ),
          if (live.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: CupertinoIcons.play_circle,
                title: 'La cancha está en silencio',
                message:
                    'No hay eventos en vivo en este momento. Abajo tienes lo que empieza pronto.',
                action: 'Actualizar',
                onAction: app.refresh,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: _LiveSummary(
                count: live.length,
                channels: app.channels.length,
              ),
            ),
            const SliverToBoxAdapter(child: SectionTitle(title: 'Ahora mismo')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => EventListCard(event: live[index]),
                childCount: live.length,
              ),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionTitle(
                title: 'Empiezan pronto',
                action: 'Agenda',
                onAction: () {},
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => EventListCard(
                  event: upcoming[index],
                  showDay: !isSameDay(upcoming[index].startsAt, DateTime.now()),
                ),
                childCount: upcoming.length,
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Text(
                'Actualizado ${formatRelativeUpdate(app.lastSync)} · horarios en tu hora local',
                style: AppText.body(10, color: p.textMuted),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _LiveSummary extends StatelessWidget {
  const _LiveSummary({required this.count, required this.channels});

  final int count;
  final int channels;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.coral.withValues(alpha: 0.20), p.surface],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.coral.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: p.coral.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.dot_radiowaves_left_right,
              color: p.coral,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count señales en directo',
                  style: AppText.display(17, weight: 700, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '$channels canales 24/7 disponibles',
                  style: AppText.body(10.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          const LivePill(compact: true),
        ],
      ),
    );
  }
}
