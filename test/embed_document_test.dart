import 'package:flutter_test/flutter_test.dart';
import 'package:paraver/data/embed_document.dart';

const _page = '''
<!doctype html>
<html>
<head>
<style>html,body{margin:0}</style>
<script>window['ad']='x';var aclib={runPop:function(){}};</script>
<script>aclib.runPop({zoneId:'1'});</script>
<script data-cfasync="false" async src="//laborer.example.com/ad.js"></script>
<script src="https://cdn.jsdelivr.net/npm/pako@2/dist/pako.min.js"></script>
<script src="https://cdn.jwplayer.com/libraries/KB5zFt7A.js"></script>
</head>
<body>
<div id="player"></div>
<script>
const SRC = "https://edge.example/premium1/index.m3u8";
const EDGE = "https://edge.example";
if (!isEmbedded()) {
  blockPlayer('This player only works when embedded.');
} else if (SRC) {
  jwplayer('player');
}
</script>
</body>
</html>
''';

void main() {
  test('strips ad scripts and keeps the player', () {
    final clean = sanitizeEmbedHtml(_page);

    expect(clean, isNot(contains('aclib')));
    expect(clean, isNot(contains('runPop')));
    expect(clean, isNot(contains('laborer.example.com')));
    expect(clean, contains('cdn.jsdelivr.net'));
    expect(clean, contains('cdn.jwplayer.com'));
    expect(clean, contains('const SRC'));
    expect(clean, contains('jwplayer('));
  });

  test('allows the player to run outside an iframe', () {
    final clean = sanitizeEmbedHtml(_page);

    expect(clean, isNot(contains('!isEmbedded()')));
    expect(clean, contains('if (false)'));
  });

  test('blocks popups before any page script runs', () {
    final clean = sanitizeEmbedHtml(_page);
    final guard = clean.indexOf('window.open = function');
    final player = clean.indexOf('const SRC');

    expect(guard, greaterThan(0));
    expect(guard, lessThan(player));
    expect(clean, contains('href.indexOf(\'https://dembed.st/\')'));
  });
}
