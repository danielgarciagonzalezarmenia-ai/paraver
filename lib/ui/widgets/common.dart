import 'package:flutter/cupertino.dart';

import '../../core/theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.background, p.backgroundAlt, p.background],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            left: -100,
            child: _Glow(
              color: p.blue.withValues(alpha: p.isDark ? 0.18 : 0.10),
              size: 360,
            ),
          ),
          Positioned(
            bottom: -180,
            right: -140,
            child: _Glow(
              color: p.accent.withValues(alpha: p.isDark ? 0.09 : 0.14),
              size: 420,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: AppBackground(child: SafeArea(bottom: false, child: child)),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: [
          BoxShadow(
            color: p.accent.withValues(alpha: 0.22),
            blurRadius: size * 0.7,
            spreadRadius: -size * 0.2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.27),
        child: Image.asset(
          'assets/icon/icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: compact ? 30 : 38),
        SizedBox(width: compact ? 9 : 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: AppText.display(
                  compact ? 17 : 21,
                  weight: 700,
                  letterSpacing: 1.2,
                  color: p.text,
                ),
                children: [
                  const TextSpan(text: 'PARA'),
                  TextSpan(
                    text: 'VER',
                    style: TextStyle(color: p.accent),
                  ),
                ],
              ),
            ),
            if (!compact)
              Text(
                'DEPORTE EN VIVO · SIN RUIDO',
                style: AppText.body(
                  8.5,
                  weight: 600,
                  color: p.textMuted,
                  letterSpacing: 1.4,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 19,
    this.background,
    this.color,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background ?? p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
            ),
            child: Icon(icon, size: iconSize, color: color ?? p.text),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.coral,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.background, width: 2),
                ),
                child: Text(
                  badge! > 99 ? '99+' : '$badge',
                  style: AppText.body(
                    9,
                    weight: 700,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    this.title,
    this.subtitle,
    this.brand = false,
    this.trailing,
    this.eyebrow,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 18),
  });

  final String? title;
  final String? subtitle;
  final bool brand;
  final Widget? trailing;
  final String? eyebrow;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (brand) {
      return Padding(
        padding: padding,
        child: Row(children: [const BrandLockup(), const Spacer(), ?trailing]),
      );
    }
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppText.body(
                      10,
                      weight: 700,
                      color: p.accent,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title ?? '',
                  style: AppText.display(34, weight: 700, color: p.text),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppText.body(13, color: p.textMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 26, 20, 12),
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title.toUpperCase(),
            style: AppText.body(
              11,
              weight: 700,
              color: p.text,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: AppText.body(11, weight: 600, color: p.textMuted),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 12,
                    color: p.textMuted,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LivePill extends StatefulWidget {
  const LivePill({
    super.key,
    this.label = 'EN VIVO',
    this.compact = false,
    this.pulse = true,
  });

  final String label;
  final bool compact;
  final bool pulse;

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dot = Container(
      width: widget.compact ? 5 : 6,
      height: widget.compact ? 5 : 6,
      decoration: BoxDecoration(color: p.coral, shape: BoxShape.circle),
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 7 : 9,
        vertical: widget.compact ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: p.coral.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.coral.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  Opacity(opacity: 0.4 + (_controller.value * 0.6), child: dot),
            )
          else
            dot,
          SizedBox(width: widget.compact ? 4 : 5),
          Text(
            widget.label,
            style: AppText.body(
              widget.compact ? 8.5 : 9.5,
              weight: 800,
              color: p.coral,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.icon,
    this.border,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? p.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border ?? p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.body(10, weight: 600, color: fg, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class SportBadge extends StatelessWidget {
  const SportBadge({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 34,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.52,
        color: const Color(0xFF080D14).withValues(alpha: 0.9),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
            ),
            child: Icon(icon, size: 26, color: p.accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.display(20, weight: 700, color: p.text),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body(12.5, color: p.textMuted, height: 1.45),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 18),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: p.accent,
              borderRadius: BorderRadius.circular(30),
              onPressed: onAction,
              child: Text(
                action!,
                style: AppText.body(13, weight: 700, color: p.onAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.coral.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.coral.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 18,
            color: p.coral,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.body(12, color: p.text, height: 1.35),
            ),
          ),
          if (onRetry != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 32),
              onPressed: onRetry,
              child: Text(
                'Reintentar',
                style: AppText.body(11, weight: 700, color: p.accent),
              ),
            ),
        ],
      ),
    );
  }
}
