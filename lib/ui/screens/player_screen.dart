import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/sports.dart';
import '../../core/theme.dart';
import '../../data/playlist_proxy.dart';
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
  VideoPlayerController? _controller;
  PlaylistProxy? _proxy;
  int _sourceIndex = 0;
  int _generation = 0;
  bool _loading = true;
  String? _error;
  bool _muted = false;
  bool _fullscreen = false;
  bool _controlsVisible = true;
  bool _lastBuffering = false;
  bool _lastPlaying = false;
  Timer? _hideTimer;
  Timer? _safeTimer;

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
    _hideTimer?.cancel();
    _safeTimer?.cancel();
    _generation++;
    _controller?.removeListener(_onVideoValue);
    _controller?.dispose();
    _proxy?.stop();
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
      _controller?.pause();
    }
  }

  Future<void> _loadSource(int index, {bool force = false}) async {
    final generation = ++_generation;
    _safeTimer?.cancel();
    setState(() {
      _sourceIndex = index;
      _loading = true;
      _error = null;
      _controlsVisible = true;
      _lastBuffering = false;
      _lastPlaying = false;
    });
    await _disposeSession();
    if (!mounted || generation != _generation) return;

    try {
      final resolved = await context.app.streams
          .resolve(widget.target.sources[index].id, force: force)
          .timeout(const Duration(seconds: 25));
      if (!mounted || generation != _generation) return;

      final proxy = PlaylistProxy(context.app.streams, resolved);
      final url = await proxy.start().timeout(const Duration(seconds: 25));
      if (!mounted || generation != _generation) {
        await proxy.stop();
        return;
      }
      _proxy = proxy;

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      await controller.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      await controller.setVolume(_muted ? 0 : 1);
      await controller.play();
      controller.addListener(_onVideoValue);
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _controlsVisible = true;
      });
      _scheduleHide();
    } catch (_) {
      if (!mounted || generation != _generation) return;
      final controller = _controller;
      _controller = null;
      controller?.removeListener(_onVideoValue);
      await controller?.dispose();
      await _proxy?.stop();
      _proxy = null;
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _controlsVisible = false;
        _error =
            'La señal no respondió. Puede estar fuera de línea o requerir otra fuente.';
      });
    }
  }

  Future<void> _disposeSession() async {
    _hideTimer?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onVideoValue);
    await controller?.dispose();
    final proxy = _proxy;
    _proxy = null;
    await proxy?.stop();
  }

  void _onVideoValue() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.hasError && _error == null) {
      setState(() {
        _loading = false;
        _controlsVisible = false;
        _error =
            'No pudimos reproducir esta fuente. Prueba con otra señal o vuelve a intentar.';
      });
      return;
    }
    if (value.isBuffering != _lastBuffering ||
        value.isPlaying != _lastPlaying) {
      _lastBuffering = value.isBuffering;
      _lastPlaying = value.isPlaying;
      if (mounted) setState(() {});
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _safeTimer?.cancel();
    final controller = _controller;
    if (controller == null ||
        _loading ||
        _error != null ||
        !controller.value.isPlaying) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_loading || _error != null) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      _hideTimer?.cancel();
      setState(() => _controlsVisible = true);
    } else {
      await controller.play();
      _scheduleHide();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    _muted = !_muted;
    await controller.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  Future<void> _toggleFullscreen() async {
    _hideTimer?.cancel();
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
    if (mounted) _scheduleHide();
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
    final ratio = _controller?.value.isInitialized == true
        ? _controller!.value.aspectRatio
        : 16 / 9;

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
              ? _buildFullscreen(style, ratio)
              : _buildPortrait(p, style, ratio),
        ),
      ),
    );
  }

  Widget _buildPortrait(Palette p, SportStyle style, double ratio) {
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
                aspectRatio: ratio <= 0 ? 16 / 9 : ratio,
                child: _VideoSurface(
                  controller: _controller,
                  loading: _loading,
                  error: _error,
                  buffering: _lastBuffering,
                  controlsVisible: _controlsVisible,
                  muted: _muted,
                  fullscreen: false,
                  title: widget.target.title,
                  subtitle: _source.name,
                  onTap: _toggleControls,
                  onBack: () => Navigator.of(context).pop(),
                  onPlay: _togglePlay,
                  onMute: _toggleMute,
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

  Widget _buildFullscreen(SportStyle style, double ratio) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: _VideoSurface(
          controller: _controller,
          loading: _loading,
          error: _error,
          buffering: _lastBuffering,
          controlsVisible: _controlsVisible,
          muted: _muted,
          fullscreen: true,
          title: widget.target.title,
          subtitle: _source.name,
          onTap: _toggleControls,
          onBack: _exitFullscreen,
          onPlay: _togglePlay,
          onMute: _toggleMute,
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
    required this.loading,
    required this.error,
    required this.buffering,
    required this.controlsVisible,
    required this.muted,
    required this.fullscreen,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onBack,
    required this.onPlay,
    required this.onMute,
    required this.onFullscreen,
    required this.onRetry,
    required this.sources,
    required this.sourceIndex,
    required this.onSource,
  });

  final VideoPlayerController? controller;
  final bool loading;
  final String? error;
  final bool buffering;
  final bool controlsVisible;
  final bool muted;
  final bool fullscreen;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onMute;
  final VoidCallback onFullscreen;
  final VoidCallback onRetry;
  final List<ChannelRef> sources;
  final int sourceIndex;
  final ValueChanged<int> onSource;

  @override
  Widget build(BuildContext context) {
    final initialized = controller?.value.isInitialized == true;
    final playing = controller?.value.isPlaying == true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF000000)),
          if (initialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            ),
          if (initialized && !playing && !loading && error == null)
            Center(
              child: _RoundPlayButton(
                icon: CupertinoIcons.play_fill,
                onTap: onPlay,
                size: 66,
              ),
            ),
          if (loading)
            _LoadingOverlay(
              title: 'Conectando señal',
              subtitle: 'Reproductor nativo · sin anuncios',
            ),
          if (buffering && !loading && error == null)
            const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: Color(0xFFD7FF3E),
              ),
            ),
          AnimatedOpacity(
            opacity: controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !controlsVisible,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xB3000000),
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0xB3000000),
                        ],
                        stops: [0, 0.28, 0.62, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: fullscreen ? 14 : 8,
                    left: 10,
                    right: 10,
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
                                maxLines: fullscreen ? 1 : 2,
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
                        if (playing)
                          const LivePill(compact: true, pulse: false),
                        const SizedBox(width: 8),
                        _GlassButton(
                          icon: muted
                              ? CupertinoIcons.speaker_slash_fill
                              : CupertinoIcons.speaker_2_fill,
                          onTap: onMute,
                        ),
                      ],
                    ),
                  ),
                  if (initialized)
                    Center(
                      child: _RoundPlayButton(
                        icon: playing
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        onTap: onPlay,
                        size: 54,
                        translucent: true,
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: fullscreen ? 16 : 10,
                    child: Row(
                      children: [
                        const _GlassPill(
                          icon: CupertinoIcons.shield_fill,
                          label: 'SIN ANUNCIOS',
                        ),
                        const Spacer(),
                        _GlassButton(
                          icon: fullscreen
                              ? CupertinoIcons.arrow_down_right
                              : CupertinoIcons.arrow_up_left_arrow_down_right,
                          onTap: onFullscreen,
                        ),
                      ],
                    ),
                  ),
                ],
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
      ),
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

class _RoundPlayButton extends StatelessWidget {
  const _RoundPlayButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.translucent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: translucent ? const Color(0x33000000) : p.accent,
          shape: BoxShape.circle,
          border: Border.all(
            color: translucent ? const Color(0x40FFFFFF) : p.accent,
          ),
        ),
        child: Icon(
          icon,
          color: translucent ? const Color(0xFFFFFFFF) : p.onAccent,
          size: size * 0.4,
        ),
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
                        'La app reproduce la señal HLS directamente. No se carga la página del proveedor, así que no hay pop-ups ni anuncios.',
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
