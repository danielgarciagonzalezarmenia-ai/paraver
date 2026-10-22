import 'package:flutter/cupertino.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'widgets/cards.dart';
import 'widgets/common.dart';

enum _SearchScope { all, events, channels }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  _SearchScope _scope = _SearchScope.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.app;
    final q = _query.toLowerCase();
    final events = q.isEmpty
        ? <SportEvent>[]
        : app.events.where((event) {
            if (event.title.toLowerCase().contains(q)) return true;
            if (event.category.toLowerCase().contains(q)) return true;
            return event.channels.any((c) => c.name.toLowerCase().contains(q));
          }).toList();
    final channels = q.isEmpty
        ? <Channel>[]
        : app.channels
              .where((channel) => channel.name.toLowerCase().contains(q))
              .toList();

    final showEvents = _scope != _SearchScope.channels;
    final showChannels = _scope != _SearchScope.events;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(CupertinoIcons.back, color: p.text, size: 22),
                    ),
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        child: CupertinoTextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          placeholder: 'Equipo, evento o canal',
                          placeholderStyle: AppText.body(
                            13,
                            color: p.textMuted,
                          ),
                          style: AppText.body(13, color: p.text),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              CupertinoIcons.search,
                              size: 17,
                              color: p.textMuted,
                            ),
                          ),
                          decoration: null,
                          cursorColor: p.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _ScopeChip(
                      label: 'Todo',
                      selected: _scope == _SearchScope.all,
                      onTap: () => setState(() => _scope = _SearchScope.all),
                    ),
                    const SizedBox(width: 6),
                    _ScopeChip(
                      label: 'Eventos',
                      selected: _scope == _SearchScope.events,
                      onTap: () => setState(() => _scope = _SearchScope.events),
                    ),
                    const SizedBox(width: 6),
                    _ScopeChip(
                      label: 'Canales',
                      selected: _scope == _SearchScope.channels,
                      onTap: () =>
                          setState(() => _scope = _SearchScope.channels),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _query.isEmpty
                    ? _IdleSuggestions(app: app)
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          if (showEvents && events.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: SectionTitle(
                                title: 'Eventos · ${events.length}',
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  20,
                                  10,
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    EventListCard(event: events[index]),
                                childCount: events.length,
                              ),
                            ),
                          ],
                          if (showChannels && channels.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: SectionTitle(
                                title: 'Canales · ${channels.length}',
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
                                  20,
                                  10,
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 230,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.5,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      ChannelTile(channel: channels[index]),
                                  childCount: channels.length,
                                ),
                              ),
                            ),
                          ],
                          if ((!showEvents || events.isEmpty) &&
                              (!showChannels || channels.isEmpty))
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(
                                icon: CupertinoIcons.search,
                                title: 'Sin coincidencias',
                                message:
                                    'No encontramos "$_query". Prueba con el nombre de un equipo o canal.',
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 30)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? p.accent : p.border),
        ),
        child: Text(
          label,
          style: AppText.body(
            11,
            weight: selected ? 700 : 500,
            color: selected ? p.onAccent : p.textMuted,
          ),
        ),
      ),
    );
  }
}

class _IdleSuggestions extends StatelessWidget {
  const _IdleSuggestions({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final live = app.liveEvents.take(4).toList();
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 4),
          child: Text(
            'Busca en ${app.events.length} eventos y ${app.channels.length} canales',
            style: AppText.body(11.5, color: p.textMuted),
          ),
        ),
        if (live.isEmpty)
          const EmptyState(
            icon: CupertinoIcons.search,
            title: 'Encuentra tu señal',
            message:
                'Escribe el nombre de un equipo, liga o canal. Los resultados aparecen al instante.',
          )
        else ...[
          const SectionTitle(title: 'En vivo ahora'),
          for (final event in live) EventListCard(event: event),
        ],
      ],
    );
  }
}
