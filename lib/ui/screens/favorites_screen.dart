import 'package:flutter/cupertino.dart';

import '../../state/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final events = app.favoriteEvents.toList()
      ..sort((a, b) => a.event!.startsAt.compareTo(b.event!.startsAt));
    final channels = app.favoriteChannels;
    final total = events.length + channels.length;

    return PageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: app.refresh),
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Guardados',
              eyebrow: 'Tu lista',
              subtitle: total == 0
                  ? 'Marca eventos y canales para tenerlos a mano'
                  : '$total elementos guardados',
            ),
          ),
          if (total == 0)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: CupertinoIcons.star,
                title: 'Tu lista está vacía',
                message:
                    'Toca la estrella en cualquier evento o canal y aparecerá aquí, incluso sin conexión.',
              ),
            )
          else ...[
            if (events.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  title: 'Eventos',
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      EventListCard(event: events[index].event!),
                  childCount: events.length,
                ),
              ),
            ],
            if (channels.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  title: 'Canales',
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        ChannelTile(channel: channels[index].channel!),
                    childCount: channels.length,
                  ),
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
