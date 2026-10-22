import 'dlive_client.dart';

class ResolvedStream {
  const ResolvedStream({
    required this.channelId,
    required this.slug,
    required this.edge,
    required this.playlistUrl,
    required this.resolvedAt,
  });

  final String channelId;
  final String slug;
  final String edge;
  final String playlistUrl;
  final DateTime resolvedAt;
}

class StreamResolver {
  StreamResolver(this._client);

  final DliveClient _client;
  final Map<String, ResolvedStream> _cache = {};

  Future<ResolvedStream> resolve(String channelId, {bool force = false}) async {
    final cached = _cache[channelId];
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.resolvedAt) <
            const Duration(minutes: 4)) {
      return cached;
    }

    final html = await _client.fetchPlayerPage(channelId);
    final source =
        RegExp(r'const SRC = "([^"]+)"').firstMatch(html)?.group(1) ??
        RegExp(
          r'''(?:file|src)\s*[:=]\s*["'](https?://[^"']+?\.m3u8[^"']*)''',
        ).firstMatch(html)?.group(1);
    final channel =
        RegExp(r'const CHANNEL = "([^"]+)"').firstMatch(html)?.group(1) ??
        'premium$channelId';
    final edge =
        RegExp(r'const EDGE = "([^"]+)"').firstMatch(html)?.group(1) ??
        _edgeFromPlaylist(source);

    if (source == null || edge == null) {
      throw DliveException(
        'Esta fuente no está disponible. Prueba con otro canal.',
      );
    }

    final resolved = ResolvedStream(
      channelId: channelId,
      slug: channel,
      edge: edge,
      playlistUrl: source,
      resolvedAt: DateTime.now(),
    );
    _cache[channelId] = resolved;
    return resolved;
  }

  String? _edgeFromPlaylist(String? source) {
    if (source == null) return null;
    final uri = Uri.tryParse(source);
    if (uri == null || uri.host.isEmpty) return null;
    return '${uri.scheme}://${uri.host}';
  }

  Future<String> fetchToken(ResolvedStream stream) async {
    final data = await _client.fetchJson(
      '${stream.edge}/api/playlist-token?slug=${Uri.encodeComponent(stream.slug)}',
      headers: const {
        'User-Agent': DliveClient.userAgent,
        'Accept': 'application/json',
        'Origin': 'https://dembed.st',
        'Referer': 'https://dembed.st/',
        'Cache-Control': 'no-store',
      },
    );
    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw DliveException('No se pudo firmar la señal.');
    }
    return token;
  }

  Uri signedPlaylist(Uri playlist, String token) {
    final query = Map<String, String>.from(playlist.queryParameters);
    query['t'] = token;
    return playlist.replace(queryParameters: query);
  }
}
