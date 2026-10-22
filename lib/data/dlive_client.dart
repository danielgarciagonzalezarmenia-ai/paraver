import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'dlive_parser.dart';

class DliveException implements Exception {
  DliveException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DliveClient {
  DliveClient({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'https://dlive.sx';
  static const embedBase = 'https://dembed.st';

  static const userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
      'Mobile/15E148 Safari/604.1';

  final http.Client _client;

  Map<String, String> get _headers => const {
    'User-Agent': userAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'es-CO,es;q=0.9,en;q=0.8',
    'Cache-Control': 'no-cache',
  };

  Future<String> fetchText(String url, {Map<String, String>? headers}) async {
    final response = await _client
        .get(Uri.parse(url), headers: headers ?? _headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DliveException('El servidor respondió ${response.statusCode}.');
    }
    return _decodeBody(response);
  }

  String _decodeBody(http.Response response) {
    final bytes = response.bodyBytes;
    final contentType = response.headers['content-type'] ?? '';
    final charset = RegExp(
      r'charset=([^;]+)',
      caseSensitive: false,
    ).firstMatch(contentType)?.group(1)?.trim().toLowerCase();
    if (charset == 'iso-8859-1' ||
        charset == 'latin1' ||
        charset == 'windows-1252') {
      return latin1.decode(bytes);
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  Future<ScheduleSnapshot> fetchSnapshot() async {
    final results = await Future.wait<List<Object>>([
      _loadHome(),
      _loadChannels(),
    ]);
    final home = results[0][0] as HomeParseResult;
    final channels = results[1][0] as List<Channel>;

    if (home.events.isEmpty && home.featured.isEmpty) {
      throw DliveException('No se pudo leer la cartelera en este momento.');
    }

    return ScheduleSnapshot(
      events: home.events,
      channels: channels,
      featured: home.featured,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<Object>> _loadHome() async {
    final html = await fetchText('$baseUrl/');
    final parsed = parseHomePage(html);
    return [parsed];
  }

  Future<List<Object>> _loadChannels() async {
    try {
      final html = await fetchText('$baseUrl/24-7-channels.php');
      return [parseChannelsPage(html)];
    } catch (_) {
      return [<Channel>[]];
    }
  }

  Future<String> fetchPlayerPage(String channelId) {
    return fetchText(
      '$embedBase/premiumtv/daddy.php?id=$channelId',
      headers: const {
        'User-Agent': userAgent,
        'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
        'Origin': 'https://dembed.st',
        'Referer': 'https://dembed.st/',
      },
    );
  }

  Future<Map<String, dynamic>> fetchJson(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .get(Uri.parse(url), headers: headers ?? _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DliveException('Token no disponible (${response.statusCode}).');
    }
    final decoded = jsonDecode(_decodeBody(response));
    if (decoded is! Map<String, dynamic>) {
      throw DliveException('Respuesta inesperada del servidor de señal.');
    }
    return decoded;
  }

  void dispose() {
    _client.close();
  }
}
