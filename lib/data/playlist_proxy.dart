import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'dlive_client.dart';
import 'stream_resolver.dart';

class PlayStream {
  const PlayStream({
    required this.playbackUrl,
    required this.proxy,
    required this.resolved,
  });

  final String playbackUrl;
  final PlaylistProxy proxy;
  final ResolvedStream resolved;

  Future<void> dispose() => proxy.stop();
}

class PlaylistProxy {
  PlaylistProxy(this._resolver, this._resolved);

  final StreamResolver _resolver;
  final ResolvedStream _resolved;
  final http.Client _client = http.Client();

  HttpServer? _server;
  int _port = 0;
  String? _token;
  DateTime _tokenFetchedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<String>? _tokenFlight;
  bool _closed = false;
  bool _started = false;

  static const _authHeaders = {
    'User-Agent': DliveClient.userAgent,
    'Accept': '*/*',
    'Origin': 'https://dembed.st',
    'Referer': 'https://dembed.st/',
  };

  Future<String> start() async {
    if (_started) return 'http://127.0.0.1:$_port/live.m3u8';
    _token = await _resolver.fetchToken(_resolved);
    _tokenFetchedAt = DateTime.now();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    _started = true;
    _server!.listen(_handleRequest, onError: (_) {});
    return 'http://127.0.0.1:$_port/live.m3u8';
  }

  Future<void> stop() async {
    _closed = true;
    await _server?.close(force: true);
    _server = null;
    _client.close();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.uri.path == '/health') {
        response
          ..statusCode = HttpStatus.ok
          ..write('ok');
        await response.close();
        return;
      }

      final String body;
      if (request.uri.path == '/live.m3u8') {
        body = await _fetchPlaylist(Uri.parse(_resolved.playlistUrl));
      } else if (request.uri.path == '/p') {
        final raw = request.uri.queryParameters['u'];
        if (raw == null || raw.isEmpty) {
          response.statusCode = HttpStatus.badRequest;
          response.write('missing u');
          await response.close();
          return;
        }
        final upstream = Uri.parse(raw);
        if (upstream.host == Uri.parse(_resolved.edge).host) {
          body = await _fetchPlaylist(upstream);
        } else {
          body = await _fetchExternalPlaylist(upstream);
        }
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write('not found');
        await response.close();
        return;
      }

      response.headers.contentType = ContentType(
        'application',
        'vnd.apple.mpegurl',
        charset: 'utf-8',
      );
      response.headers.set('Access-Control-Allow-Origin', '*');
      response.headers.set('Cache-Control', 'no-cache, no-store');
      response.write(body);
      await response.close();
    } catch (error) {
      if (!_closed) {
        response.statusCode = HttpStatus.badGateway;
        response.headers.contentType = ContentType.text;
        response.write('signal unavailable: $error');
        try {
          await response.close();
        } catch (_) {}
      }
    }
  }

  Future<String> _fetchPlaylist(Uri upstream, {bool retry = true}) async {
    final token = await _getToken();
    final signed = _resolver.signedPlaylist(upstream, token);
    final response = await _client
        .get(signed, headers: _authHeaders)
        .timeout(const Duration(seconds: 18));
    if ((response.statusCode == 401 || response.statusCode == 403) && retry) {
      _tokenFetchedAt = DateTime.fromMillisecondsSinceEpoch(0);
      return _fetchPlaylist(upstream, retry: false);
    }
    if (response.statusCode != 200) {
      throw DliveException('La señal devolvió ${response.statusCode}.');
    }
    return _rewritePlaylist(response.body, upstream);
  }

  Future<String> _fetchExternalPlaylist(Uri upstream) async {
    final response = await _client
        .get(upstream, headers: _authHeaders)
        .timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw DliveException('La señal devolvió ${response.statusCode}.');
    }
    return _rewritePlaylist(response.body, upstream);
  }

  Future<String> _getToken() {
    final current = _token;
    if (current != null &&
        DateTime.now().difference(_tokenFetchedAt).inSeconds < 75) {
      return Future.value(current);
    }
    final flight = _tokenFlight;
    if (flight != null) return flight;
    final future = _resolver
        .fetchToken(_resolved)
        .then((token) {
          _token = token;
          _tokenFetchedAt = DateTime.now();
          return token;
        })
        .whenComplete(() => _tokenFlight = null);
    _tokenFlight = future;
    return future;
  }

  String _rewritePlaylist(String body, Uri base) {
    final buffer = StringBuffer();
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        buffer.writeln();
        continue;
      }
      if (trimmed.startsWith('#')) {
        buffer.writeln(
          trimmed.replaceAllMapped(
            RegExp(r'URI="([^"]+)"'),
            (match) => 'URI="${_resolveUri(match.group(1)!, base)}"',
          ),
        );
        continue;
      }
      buffer.writeln(_resolveUri(trimmed, base));
    }
    return buffer.toString();
  }

  String _resolveUri(String raw, Uri base) {
    final absolute = base.resolve(raw);
    final path = absolute.path.toLowerCase();
    if (path.endsWith('.m3u8')) {
      return 'http://127.0.0.1:$_port/p?u=${Uri.encodeQueryComponent(absolute.toString())}';
    }
    return absolute.toString();
  }
}
