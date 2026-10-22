import 'package:flutter/cupertino.dart';

import '../../core/theme.dart';
import '../../data/local_store.dart';
import '../../state/app_state.dart';
import '../../utils/time_utils.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.app;

    return PageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Ajustes',
              eyebrow: 'ParaVer',
              subtitle: 'Menos ruido, más deporte.',
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Apariencia',
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _ThemeOption(
                          icon: CupertinoIcons.device_phone_portrait,
                          label: 'Sistema',
                          selected: app.themeChoice == ThemeChoice.system,
                          onTap: () => app.setTheme(ThemeChoice.system),
                        ),
                        const SizedBox(width: 7),
                        _ThemeOption(
                          icon: CupertinoIcons.moon_fill,
                          label: 'Oscuro',
                          selected: app.themeChoice == ThemeChoice.dark,
                          onTap: () => app.setTheme(ThemeChoice.dark),
                        ),
                        const SizedBox(width: 7),
                        _ThemeOption(
                          icon: CupertinoIcons.sun_max_fill,
                          label: 'Claro',
                          selected: app.themeChoice == ThemeChoice.light,
                          onTap: () => app.setTheme(ThemeChoice.light),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.accent.withValues(alpha: 0.20), p.surface],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.accent.withValues(alpha: 0.26)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      CupertinoIcons.shield_lefthalf_fill,
                      color: p.onAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escudo anti-anuncios',
                          style: AppText.display(
                            17,
                            weight: 700,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ParaVer extrae la señal y la reproduce con el reproductor nativo del teléfono. Nunca carga la página del embed: no hay pop-ups, redirecciones ni anuncios.',
                          style: AppText.body(
                            11.5,
                            color: p.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Datos',
              child: Column(
                children: [
                  _Row(
                    icon: CupertinoIcons.arrow_clockwise,
                    title: 'Actualizar cartelera',
                    subtitle: formatRelativeUpdate(app.lastSync),
                    trailing: app.isLoading
                        ? const CupertinoActivityIndicator(radius: 9)
                        : null,
                    onTap: app.isLoading ? null : app.refresh,
                  ),
                  _divider(p),
                  _Row(
                    icon: CupertinoIcons.calendar,
                    title: 'Eventos en agenda',
                    subtitle: '${app.events.length} cargados',
                  ),
                  _divider(p),
                  _Row(
                    icon: CupertinoIcons.tv,
                    title: 'Canales 24/7',
                    subtitle: '${app.channels.length} disponibles',
                  ),
                  _divider(p),
                  _Row(
                    icon: CupertinoIcons.trash,
                    title: 'Limpiar caché',
                    subtitle: 'Borra la cartelera descargada',
                    destructive: true,
                    onTap: () => _confirmClear(context, app),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Cómo funciona',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Step(
                      number: '01',
                      title: 'Cartelera viva',
                      text:
                          'Leemos los eventos y canales públicos y los ordenamos en tu hora local.',
                    ),
                    _Step(
                      number: '02',
                      title: 'Fuente directa',
                      text:
                          'Al abrir un evento resolvemos la señal HLS original, sin páginas intermedias.',
                    ),
                    _Step(
                      number: '03',
                      title: 'Reproductor nativo',
                      text:
                          'Tu iPhone reproduce el video con AVPlayer. Cero publicidad inyectada.',
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVISO LEGAL',
                    style: AppText.body(
                      9,
                      weight: 800,
                      color: p.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ParaVer no aloja, transmite ni controla el contenido. Las señales pertenecen a sus respectivos titulares y provienen de fuentes públicas de terceros. La app solo actúa como reproductor.',
                    style: AppText.body(10.5, color: p.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                children: [
                  const BrandLogo(size: 34),
                  const SizedBox(height: 8),
                  Text(
                    'PARAVER 1.0.0',
                    style: AppText.body(
                      9,
                      weight: 800,
                      color: p.textMuted,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Hecho para ver deporte sin ruido.',
                    style: AppText.body(10.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _divider(Palette p) => Container(
    height: 1,
    margin: const EdgeInsets.only(left: 56, right: 16),
    color: p.border,
  );

  Future<void> _confirmClear(BuildContext context, AppState app) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('¿Limpiar caché?'),
        content: const Text(
          'Se borrará la cartelera descargada. Tus guardados se mantienen.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (result == true) {
      await app.clearCache();
      await app.refresh();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppText.body(
                9,
                weight: 800,
                color: p.textMuted,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? p.accent : p.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? p.accent : p.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: selected ? p.onAccent : p.textMuted),
              const SizedBox(height: 5),
              Text(
                label,
                style: AppText.body(
                  10.5,
                  weight: 600,
                  color: selected ? p.onAccent : p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (destructive ? p.coral : p.accent).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 16,
                color: destructive ? p.coral : p.accent,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(
                      12.5,
                      weight: 600,
                      color: destructive ? p.coral : p.text,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: AppText.body(9.5, color: p.textMuted)),
                ],
              ),
            ),
            trailing ??
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: p.textMuted.withValues(alpha: 0.6),
                ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.text,
    this.last = false,
  });

  final String number;
  final String title;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: AppText.mono(13, weight: 700, color: p.accent)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(11.5, weight: 700, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AppText.body(10.5, color: p.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
