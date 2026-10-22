import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paraver/data/dlive_parser.dart';

const _fixture = '''
<html><body>
  <a class="upcoming-card" href="/watch.php?id=9">
    <div class="upcoming-card__title">Fulham vs Arsenal</div>
    <img src="//cdn.example.com/cover.jpg">
  </a>
  <div class="schedule__day">
    <div class="schedule__dayTitle">Saturday, August 15, 2026</div>
    <div class="schedule__category">
      <div class="card__meta">⚽ Football</div>
      <div class="schedule__event">
        <div class="schedule__eventHeader" data-title="Fulham vs Arsenal" data-time="20:00">
          <div class="schedule__time">20:00</div>
          <div class="schedule__eventTitle">Fulham vs Arsenal</div>
          <div class="schedule__channels">
            <a href="/watch.php?id=42" title="Sky Sports">HD</a>
            <a href="/watch.php?id=43" title="DAZN">SD</a>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="schedule__day">
    <div class="schedule__dayTitle">Saturday, August 15, 2026</div>
    <div class="schedule__category">
      <div class="card__meta">🎾 Tennis</div>
      <div class="schedule__event">
        <div class="schedule__eventHeader" data-title="No time" data-time="TBD">
          <div class="schedule__eventTitle">No time</div>
          <div class="schedule__channels">
            <a href="/watch.php?id=44">HD</a>
          </div>
        </div>
      </div>
    </div>
  </div>
</body></html>
''';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('extracts channel ids from both link formats', () {
    expect(channelIdFromHref('/watch.php?id=42'), '42');
    expect(channelIdFromHref('https://dlive.sx/stream-77.php'), '77');
    expect(channelIdFromHref('/watch.php?id=abc'), isNull);
    expect(channelIdFromHref(null), isNull);
  });

  test('parses featured items and avoids duplicate titles', () {
    const html = '''
      <a class="upcoming-card" href="/watch.php?id=9">
        <div class="upcoming-card__title">Fulham vs Arsenal</div>
        <img src="//cdn.example.com/cover.jpg">
      </a>
      <a class="upcoming-card" href="/watch.php?id=10">
        <div class="upcoming-card__title">Fulham vs Arsenal</div>
      </a>
      <a class="upcoming-card" href="/watch.php?id=11">
        <div class="upcoming-card__title">Real Madrid vs Barcelona</div>
      </a>
    ''';
    final result = parseHomePage(html);
    expect(result.featured, hasLength(2));
    expect(result.featured.first.channelId, '9');
    expect(result.featured.first.imageUrl, 'https://cdn.example.com/cover.jpg');
    expect(result.featured.last.channelId, '11');
  });

  test('parses events, channels, category and ignores invalid times', () {
    final result = parseHomePage(_fixture, now: DateTime(2026, 8, 15));
    expect(result.events, hasLength(1));
    final event = result.events.single;
    expect(event.title, 'Fulham vs Arsenal');
    expect(event.category, 'Football');
    expect(event.channels.map((c) => c.id), ['42', '43']);
    expect(event.channels.first.badge, 'HD');
    expect(event.channels.last.badge, 'SD');
    expect(event.startsAt.year, 2026);
    expect(event.startsAt.month, 8);
    expect(event.startsAt.day, 15);
    expect(event.isPpv, isFalse);
  });

  test('parses the 24/7 channels page and sorts by name', () {
    const html = '''
      <a class="card" href="/watch.php?id=5">
        <div class="card__title">Zona Sports</div>
      </a>
      <a class="card" href="/watch.php?id=3">
        <div class="card__title">Alpha TV</div>
      </a>
      <a class="card" href="/watch.php?id=5">
        <div class="card__title">Zona Sports</div>
      </a>
      <a class="card" href="/watch.php?id=8"></a>
    ''';
    final channels = parseChannelsPage(html);
    expect(channels.map((c) => c.name), ['Alpha TV', 'Zona Sports']);
    expect(channels.map((c) => c.id), ['3', '5']);
  });
}
