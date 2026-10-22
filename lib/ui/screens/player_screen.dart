import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/sports.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/playback_target.dart';
import '../../state/app_state.dart';
import '../../utils/time_utils.dart';
import '../widgets/common.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.target});

  final PlaybackTarget target;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  GlobalKey _webViewKey = GlobalKey();
  int _sourceIndex = 0;
  int _generation = 0;
  bool _loading = true;
  String? _error;
  bool _fullscreen = false;
  Timer? _loadingTimer;

  ChannelRef get _source => widget.target.sources[_sourceIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSource(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingTimer?.cancel();
    _generation++;
    _controller = null;
    if (_fullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _controller;
      if (controller != null) {
        unawaited(
          controller.runJavaScript(
            'var v=document.querySelector("video");if(v){v.pause();}',
          ),
        );
      }
    }
  }

  Future<void> _loadSource(int index, {bool force = false}) async {
    final generation = ++_generation;
    _loadingTimer?.cancel();
    setState(() {
      _sourceIndex = index;
      _loading = true;
      _error = null;
      _controller = null;
      _webViewKey = GlobalKey();
    });

    try {
      final html = await context.app.embeds
          .load(widget.target.sources[index].id, force: force)
          .timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) return;

      final controller = _createController();
      _controller = controller;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0xFF000000));

      final platform = controller.platform;
      if (platform is AndroidWebViewController) {
        await platform.setMediaPlaybackRequiresUserGesture(false);
      }

      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted || generation != _generation) return;
            _loadingTimer?.cancel();
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || generation != _generation) return;
            if (error.isForMainFrame != true) return;
            _fail(
              'No se pudo cargar el reproductor. Revisa tu conexión e inténtalo de nuevo.',
            );
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            const safeSchemes = {'about', 'data', 'blob'};
            if (safeSchemes.contains(uri.scheme)) {
              return NavigationDecision.navigate;
            }
            if (uri.host == 'dembed.st' || uri.host.endsWith('.dembed.st')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

      await controller.loadHtmlString(
        html,
        baseUrl: 'https://dembed.st/premiumtv/',
      );
      if (!mounted || generation != _generation) return;
      _loadingTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted || generation != _generation || !_loading) return;
        setState(() => _loading = false);
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _fail(
        'La señal no respondió. Puede estar fuera de línea o requerir otra fuente.',
      );
    }
  }

  WebViewController _createController() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams(
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          allowsInlineMediaPlayback: true,
          javaScriptCanOpenWindowsAutomatically: false,
        ),
      );
    }
    return WebViewController.fromPlatformCreationParams(
      AndroidWebViewControllerCreationParams(),
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    _loadingTimer?.cancel();
    setState(() {
      _loading = false;
      _error = message;
      _controller = null;
    });
  }

  Future<void> _toggleFullscreen() async {
    if (_fullscreen) {
      await _exitFullscreen();
    } else {
      setState(() => _fullscreen = true);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> _exitFullscreen() async {
    if (!_fullscreen) return;
    setState(() => _fullscreen = false);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = sportStyleFor(widget.target.category ?? '');

    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _fullscreen) {
          _exitFullscreen();
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF000000),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: _fullscreen
              ? _buildFullscreen()
              : _buildPortrait(p, style),
        ),
      ),
    );
  }

  Widget _buildPortrait(Palette p, SportStyle style) {
    return ColoredBox(
      color: p.background,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF000000),
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _VideoSurface(
                  controller: _controller,
                  webViewKey: _webViewKey,
                  loading: _loading,
                  error: _error,
                  fullscreen: false,
                  title: widget.target.title,
                  subtitle: _source.name,
                  onBack: () => Navigator.of(context).pop(),
                  onFullscreen: _toggleFullscreen,
                  onRetry: () => _loadSource(_sourceIndex, force: true),
                  sources: widget.target.sources,
                  sourceIndex: _sourceIndex,
                  onSource: (index) => _loadSource(index),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _PlayerDetails(
              target: widget.target,
              style: style,
              sourceIndex: _sourceIndex,
              onSource: (index) => _loadSource(index),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      ),
    );
  }

  Widget _buildFullscreen() {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: _VideoSurface(
          controller: _controller,
          webViewKey: _webViewKey,
          loading: _loading,
          error: _error,
          fullscreen: true,
          title: widget.target.title,
          subtitle: _source.name,
          onBack: _exitFullscreen,
          onFullscreen: _toggleFullscreen,
          onRetry: () => _loadSource(_sourceIndex, force: true),
          sources: widget.target.sources,
          sourceIndex: _sourceIndex,
          onSource: (index) => _loadSource(index),
        ),
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.controller,
    required this.webViewKey,
    required this.loading,
    required this.error,
    required this.fullscreen,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onFullscreen,
    required this.onRetry,
    required this.sources,
    required this.sourceIndex,
    required this.onSource,
  });

  final WebViewController? controller;
  final GlobalKey webViewKey;
  final bool loading;
  final String? error;
  final bool fullscreen;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;
  final VoidCallback onRetry;
  final List<ChannelRef> sources;
  final int sourceIndex;
  final ValueChanged<int> onSource;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF000000)),
        if (controller != null)
          WebViewWidget(key: webViewKey, controller: controller!),
        if (loading)
          _LoadingOverlay(
            title: 'Conectando señal',
            subtitle: 'Embed protegido · sin pop-ups',
          ),
        if (error == null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                10,
                fullscreen ? 14 : 8,
                10,
                22,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xC9000000), Color(0x00000000)],
                ),
              ),
              child: Row(
                children: [
                  _GlassButton(
                    icon: fullscreen
                        ? CupertinoIcons.arrow_down_right
                        : CupertinoIcons.back,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            fullscreen ? 12 : 12.5,
                            weight: 700,
                            color: const Color(0xFFFFFFFF),
                            height: 1.2,
                          ),
                        ),
                        if (!fullscreen) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              9.5,
                              color: const Color(0x99FFFFFF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GlassButton(
                    icon: fullscreen
                        ? CupertinoIcons.arrow_down_right
                        : CupertinoIcons.arrow_up_left_arrow_down_right,
                    onTap: onFullscreen,
                  ),
                ],
              ),
            ),
          ),
        if (error == null && !loading)
          Positioned(
            left: 14,
            bottom: fullscreen ? 16 : 10,
            child: const IgnorePointer(
              child: _GlassPill(
                icon: CupertinoIcons.shield_fill,
                label: 'SIN POP-UPS',
              ),
            ),
          ),
        if (error != null)
          _ErrorOverlay(
            message: error!,
            onRetry: onRetry,
            onBack: onBack,
            sources: sources,
            sourceIndex: sourceIndex,
            onSource: onSource,
          ),
      ],
    );
  }
}

class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Transform.scale(
                scale: 0.92 + _pulse.value * 0.08,
                child: child,
              ),
              child: const BrandLogo(size: 46),
            ),
            const SizedBox(height: 14),
            const CupertinoActivityIndicator(
              radius: 10,
              color: Color(0xFFD7FF3E),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: AppText.body(
                12.5,
                weight: 700,
                color: const Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.subtitle,
              style: AppText.body(9.5, color: const Color(0x8CFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onBack,
    required this.sources,
    required this.sourceIndex,
    required this.onSource,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final List<ChannelRef> sources;
  final int sourceIndex;
  final ValueChanged<int> onSource;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: const Color(0xF2000000),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: _GlassButton(icon: CupertinoIcons.back, onTap: onBack),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: p.coral.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.wifi_slash,
                      color: p.coral,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Señal interrumpida',
                    style: AppText.display(
                      18,
                      weight: 700,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      10.5,
                      color: const Color(0xA6FFFFFF),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 9,
                    ),
                    color: p.accent,
                    borderRadius: BorderRadius.circular(30),
                    onPressed: onRetry,
                    child: Text(
                      'Reintentar',
                      style: AppText.body(12, weight: 700, color: p.onAccent),
                    ),
                  ),
                  if (sources.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 30,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: sources.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final active = index == sourceIndex;
                          return GestureDetector(
                            onTap: () => onSource(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? p.accent
                                    : const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                sources[index].name,
                                style: AppText.body(
                                  9.5,
                                  weight: 600,
                                  color: active
                                      ? p.onAccent
                                      : const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x40000000),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Icon(icon, size: 17, color: const Color(0xFFFFFFFF)),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x40000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFFD7FF3E)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.body(
              8,
              weight: 800,
              color: const Color(0xFFFFFFFF),
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerDetails extends StatelessWidget {
  const _PlayerDetails({
    required this.target,
    required this.style,
    required this.sourceIndex,
    required this.onSource,
  });

  final PlaybackTarget target;
  final SportStyle style;
  final int sourceIndex;
  final ValueChanged<int> onSource;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SportBadge(icon: style.icon, colors: style.colors, size: 32),
              const SizedBox(width: 9),
              Text(
                style.label.toUpperCase(),
                style: AppText.body(
                  9,
                  weight: 800,
                  color: p.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (target.isLive) const LivePill(compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            target.title,
            style: AppText.display(
              26,
              weight: 700,
              color: p.text,
              height: 1.08,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.clock, size: 13, color: p.textMuted),
              const SizedBox(width: 5),
              Text(
                target.startsAt != null
                    ? '${formatTime(target.startsAt!)} · ${formatDayLabel(target.startsAt!)}'
                    : 'Transmisión continua 24/7',
                style: AppText.body(11, color: p.textMuted),
              ),
              const SizedBox(width: 12),
              Icon(
                CupertinoIcons.antenna_radiowaves_left_right,
                size: 13,
                color: p.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '${target.sources.length} fuentes',
                style: AppText.body(11, color: p.textMuted),
              ),
            ],
          ),
          if (target.sources.length > 1) ...[
            const SizedBox(height: 22),
            Text(
              'FUENTES DISPONIBLES',
              style: AppText.body(
                9,
                weight: 800,
                color: p.textMuted,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: target.sources.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final channel = target.sources[index];
                  final active = index == sourceIndex;
                  return PressableScale(
                    onTap: () => onSource(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: active ? p.accent : p.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? p.accent : p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 13,
                            color: active ? p.onAccent : p.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            channel.name,
                            style: AppText.body(
                              11,
                              weight: active ? 700 : 500,
                              color: active ? p.onAccent : p.text,
                            ),
                          ),
                          if (channel.badge.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              channel.badge,
                              style: AppText.body(
                                8,
                                weight: 800,
                                color: active
                                    ? p.onAccent.withValues(alpha: 0.7)
                                    : p.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    size: 18,
                    color: p.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reproducción limpia',
                        style: AppText.body(11.5, weight: 700, color: p.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Usamos el embed del proveedor dentro de la app. Los scripts de anuncios y las ventanas emergentes quedan bloqueados.',
                        style: AppText.body(
                          9.5,
                          color: p.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
