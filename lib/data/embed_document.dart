import 'dlive_client.dart';

const _allowedScriptHosts = <String>{
  'cdn.jsdelivr.net',
  'cdn.jwplayer.com',
  'content.jwplatform.com',
};

const _clickGuard = '''
<script>
(function () {
  window.open = function () { return null; };
  document.addEventListener('click', function (event) {
    var node = event.target;
    while (node && String(node.tagName || '').toLowerCase() !== 'a') {
      node = node.parentNode;
    }
    if (!node) return;
    var href = String(node.href || '');
    if (href.indexOf('https://dembed.st/') === 0) return;
    event.preventDefault();
    event.stopPropagation();
  }, true);
})();
</script>
''';

String sanitizeEmbedHtml(String html) {
  final scriptPattern = RegExp(
    r'<script\b([^>]*)>([\s\S]*?)</script>',
    caseSensitive: false,
  );
  var clean = html.replaceAllMapped(scriptPattern, (match) {
    final attrs = match.group(1) ?? '';
    final body = match.group(2) ?? '';
    final src = RegExp(
      r'''\bsrc\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(attrs)?.group(1);

    if (src != null) {
      final value = src.trim();
      final uri = Uri.tryParse(value.startsWith('//') ? 'https:$value' : value);
      final host = uri?.host.toLowerCase() ?? '';
      final allowed =
          _allowedScriptHosts.contains(host) ||
          host.endsWith('.jwplayer.com') ||
          host.endsWith('.jwplatform.com');
      return allowed ? match.group(0)! : '';
    }

    final lower = body.toLowerCase();
    final isPlayer =
        lower.contains('const src') ||
        lower.contains('jwplayer(') ||
        lower.contains('const edge');
    return isPlayer ? match.group(0)! : '';
  });

  clean = clean.replaceAll(
    RegExp(r'!\s*isEmbedded\s*\(\s*\)'),
    'false',
  );

  final head = RegExp(r'<head\b[^>]*>', caseSensitive: false).firstMatch(clean);
  if (head == null) return '$_clickGuard$clean';
  return clean.replaceRange(head.end, head.end, _clickGuard);
}

class EmbedDocument {
  EmbedDocument(this._client);

  final DliveClient _client;
  final Map<String, String> _cache = {};

  Future<String> load(String channelId, {bool force = false}) async {
    if (!force) {
      final cached = _cache[channelId];
      if (cached != null) return cached;
    }

    final page = await _client.fetchPlayerPage(channelId);
    final clean = sanitizeEmbedHtml(page);
    if (!clean.contains('const SRC')) {
      throw DliveException(
        'No se pudo preparar el reproductor. Prueba con otra fuente.',
      );
    }
    _cache[channelId] = clean;
    return clean;
  }

  void clear() => _cache.clear();
}
