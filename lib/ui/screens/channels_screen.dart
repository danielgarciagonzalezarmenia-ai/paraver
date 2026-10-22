import 'package:flutter/cupertino.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String? _letter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _firstLetter(String name) {
    const accents = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    var value = name.trim().toUpperCase();
    if (value.isEmpty) return '#';
    final first = value[0];
    value = accents[first] ?? first;
    return RegExp(r'[A-Z]').hasMatch(value) ? value : '#';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.app;
    final letters =
        app.channels.map((c) => _firstLetter(c.name)).toSet().toList()..sort();
    final filtered = app.channels.where((channel) {
      if (_letter != null && _firstLetter(channel.name) != _letter) {
        return false;
      }
      if (_query.isEmpty) return true;
      return channel.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return PageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: app.refresh),
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Canales',
              eyebrow: '24/7',
              subtitle: '${app.channels.length} señales siempre activas',
              trailing: RoundIconButton(
                icon: CupertinoIcons.arrow_clockwise,
                onTap: app.isLoading ? null : app.refresh,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SearchBox(
                controller: _controller,
                onChanged: (value) => setState(() => _query = value.trim()),
                onClear: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: letters.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final letter = isAll ? null : letters[index - 1];
                  final active = _letter == letter;
                  return PressableScale(
                    onTap: () => setState(() => _letter = letter),
                    child: Container(
                      width: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? p.accent : p.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? p.accent : p.border),
                      ),
                      child: Text(
                        isAll ? 'TODO' : letter!,
                        style: AppText.body(
                          isAll ? 8 : 11,
                          weight: 700,
                          color: active ? p.onAccent : p.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (app.error != null && app.hasData)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InlineError(message: app.error!, onRetry: app.refresh),
              ),
            ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: CupertinoIcons.tv,
                title: app.channels.isEmpty
                    ? 'Cargando canales'
                    : 'Sin resultados',
                message: app.channels.isEmpty
                    ? 'Actualiza la cartelera para ver los canales 24/7.'
                    : 'No encontramos canales con esa búsqueda.',
                action: 'Actualizar',
                onAction: app.refresh,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChannelTile(channel: filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(CupertinoIcons.search, size: 17, color: p.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              onChanged: onChanged,
              placeholder: 'Buscar canal…',
              placeholderStyle: AppText.body(13, color: p.textMuted),
              style: AppText.body(13, color: p.text),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: null,
              cursorColor: p.accent,
            ),
          ),
          if (controller.text.isNotEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(38, 38),
              onPressed: onClear,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 16,
                color: p.textMuted,
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
