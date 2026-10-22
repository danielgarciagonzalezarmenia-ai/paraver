import 'package:flutter/cupertino.dart';

import '../../core/sports.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../utils/time_utils.dart';
import '../search_screen.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _sportKey;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final events = app.eventsForSport(_sportKey);
    final live = events.where((e) => e.isLiveNow).toList();
    final hero = app.heroEvent;
    final featured = app.featured.where((f) => f.channelId != null).toList();
    final agenda = app.agendaFor(_sportKey);

    return PageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: app.refresh),
          SliverToBoxAdapter(
            child: _HomeHeader(liveCount: app.liveEvents.length),
          ),
          SliverToBoxAdapter(
            child: _SportFilters(
              selected: _sportKey,
              onSelect: (value) => setState(() => _sportKey = value),
            ),
          ),
          if (app.error != null && app.hasData)
            SliverToBoxAdapter(
              child: InlineError(message: app.error!, onRetry: app.refresh),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: hero != null
                  ? HeroEventCard(event: hero)
                  : const HeroFallback(),
            ),
          ),
          if (live.isNotEmpty)
            SliverToBoxAdapter(
              child: _Rail(
                title: 'En vivo ahora',
                subtitle: '${live.length} señales activas',
                events: live,
              ),
            ),
          if (featured.isNotEmpty)
            SliverToBoxAdapter(child: _FeaturedRail(items: featured)),
          if (agenda.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: CupertinoIcons.calendar,
                title: 'Sin eventos para este filtro',
                message:
                    'Prueba con otro deporte o desliza hacia abajo para actualizar la cartelera.',
                action: _sportKey == null ? null : 'Ver todos',
                onAction: () => setState(() => _sportKey = null),
              ),
            )
          else
            for (final entry in agenda.entries) ...[
              SliverToBoxAdapter(
                child: _DayHeader(label: entry.key, count: entry.value.length),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => EventListCard(event: entry.value[index]),
                  childCount: entry.value.length,
                ),
              ),
            ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.liveCount});

  final int liveCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandLockup(),
              const Spacer(),
              RoundIconButton(
                icon: CupertinoIcons.search,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const SearchScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: CupertinoIcons.arrow_clockwise,
                onTap: context.app.isLoading ? null : context.app.refresh,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatLongDate(DateTime.now()),
                  style: AppText.display(25, weight: 700, color: p.text),
                ),
              ),
              if (liveCount > 0) LivePill(label: '$liveCount EN VIVO'),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Elige un evento y mira la señal limpia, sin pop-ups.',
            style: AppText.body(12, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SportFilters extends StatelessWidget {
  const _SportFilters({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = <(String?, String)>[
      (null, 'Todos'),
      for (final sport in featuredSports) (sport.key, sport.label),
    ];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = selected == item.$1;
          return PressableScale(
            onTap: () => onSelect(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? p.accent : p.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: active ? p.accent : p.border),
              ),
              child: Text(
                item.$2,
                style: AppText.body(
                  12,
                  weight: active ? 700 : 500,
                  color: active ? p.onAccent : p.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.title,
    required this.subtitle,
    required this.events,
  });

  final String title;
  final String subtitle;
  final List<SportEvent> events;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: AppText.body(
                  11,
                  weight: 700,
                  color: p.text,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 8),
              Text(subtitle, style: AppText.body(9.5, color: p.textMuted)),
            ],
          ),
        ),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                EventMiniCard(event: events[index]),
          ),
        ),
      ],
    );
  }
}

class _FeaturedRail extends StatelessWidget {
  const _FeaturedRail({required this.items});

  final List<FeaturedItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Destacados'),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => FeaturedCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: AppText.display(21, weight: 700, color: p.text)),
          const SizedBox(width: 8),
          Text('$count eventos', style: AppText.body(10, color: p.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(bottom: 4),
              color: p.border,
            ),
          ),
        ],
      ),
    );
  }
}
