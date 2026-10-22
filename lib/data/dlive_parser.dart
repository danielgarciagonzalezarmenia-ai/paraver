import 'package:html/parser.dart' as html_parser;

import '../core/sports.dart';
import '../models/models.dart';
import '../utils/hash.dart';
import '../utils/time_utils.dart';

class HomeParseResult {
  const HomeParseResult({required this.events, required this.featured});

  final List<SportEvent> events;
  final List<FeaturedItem> featured;
}

String? channelIdFromHref(String? href) {
  if (href == null || href.trim().isEmpty) return null;
  final streamMatch = RegExp(r'stream-(\d+)\.php').firstMatch(href);
  if (streamMatch != null) return streamMatch.group(1);
  final uri = Uri.tryParse(href);
  final id = uri?.queryParameters['id'];
  if (id != null && RegExp(r'^\d+$').hasMatch(id)) return id;
  return null;
}

HomeParseResult parseHomePage(String html, {DateTime? now}) {
  final document = html_parser.parse(html);
  final events = <String, SportEvent>{};
  final featured = <FeaturedItem>[];

  for (final card in document.querySelectorAll('.upcoming-card')) {
    final title = card.querySelector('.upcoming-card__title')?.text.trim();
    if (title == null || title.isEmpty) continue;
    final href = card.attributes['href'];
    var image = card.querySelector('img')?.attributes['src']?.trim();
    if (image != null && image.startsWith('//')) image = 'https:$image';
    if (featured.any((f) => f.title == title)) continue;
    featured.add(
      FeaturedItem(
        title: title,
        imageUrl: image,
        channelId: channelIdFromHref(href),
      ),
    );
  }

  for (final day in document.querySelectorAll('.schedule__day')) {
    final dayTitle =
        day.querySelector('.schedule__dayTitle')?.text.trim() ?? '';
    final dayDate = parseScheduleDate(dayTitle);
    if (dayDate == null) continue;

    for (final category in day.querySelectorAll('.schedule__category')) {
      final rawCategory =
          category.querySelector('.card__meta')?.text.trim() ?? 'Otros';
      final categoryName = stripEmoji(rawCategory);
      final forcedLive = rawCategory.toLowerCase().contains('live now');

      for (final element in category.querySelectorAll('.schedule__event')) {
        final header = element.querySelector('.schedule__eventHeader');
        final timeText =
            element.querySelector('.schedule__time')?.text.trim() ??
            header?.attributes['data-time'] ??
            '';
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeText);
        if (match == null) continue;
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);

        final title =
            element
                .querySelector('.schedule__eventTitle')
                ?.text
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim() ??
            (header?.attributes['data-title'] ?? '').trim();
        if (title.isEmpty) continue;

        final channels = <String, ChannelRef>{};
        for (final anchor in element.querySelectorAll(
          '.schedule__channels a',
        )) {
          final id = channelIdFromHref(anchor.attributes['href']);
          if (id == null) continue;
          final name = (anchor.attributes['title'] ?? anchor.text).trim();
          final badge = anchor.text.trim().toUpperCase();
          final key = '$id|$name';
          channels.putIfAbsent(
            key,
            () => ChannelRef(
              id: id,
              name: name.isEmpty ? 'Canal $id' : name,
              badge: badge == 'HD' || badge == 'SD' || badge == 'FHD'
                  ? badge
                  : 'HD',
            ),
          );
        }
        if (channels.isEmpty) continue;

        final startsAt = ukWallClockToLocal(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          hour,
          minute,
        );

        final id =
            'evt-${stableHash('$dayTitle|$title|${dayDate.toIso8601String()}|$timeText').toRadixString(16)}';
        final event = SportEvent(
          id: id,
          title: title,
          category: categoryName.isEmpty ? 'Otros' : categoryName,
          startsAt: startsAt,
          channels: channels.values.toList(),
          isPpv: categoryName.toLowerCase().contains('ppv'),
          forcedLive: forcedLive,
        );

        final existing = events[event.id];
        if (existing == null) {
          events[event.id] = event;
        } else {
          final merged = <String, ChannelRef>{
            for (final c in existing.channels) '${c.id}|${c.name}': c,
            for (final c in event.channels) '${c.id}|${c.name}': c,
          };
          events[event.id] = SportEvent(
            id: existing.id,
            title: existing.title,
            category: existing.category,
            startsAt: existing.startsAt,
            channels: merged.values.toList(),
            isPpv: existing.isPpv || event.isPpv,
            forcedLive: existing.forcedLive || event.forcedLive,
          );
        }
      }
    }
  }

  final reference = now ?? DateTime.now();
  final earliest = reference.subtract(const Duration(hours: 8));
  final latest = reference.add(const Duration(days: 9));
  final visible =
      events.values
          .where(
            (e) => e.startsAt.isAfter(earliest) && e.startsAt.isBefore(latest),
          )
          .toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  return HomeParseResult(events: visible, featured: featured);
}

List<Channel> parseChannelsPage(String html) {
  final document = html_parser.parse(html);
  final channels = <String, Channel>{};
  for (final card in document.querySelectorAll('.card')) {
    final id = channelIdFromHref(card.attributes['href']);
    if (id == null) continue;
    final name =
        card.querySelector('.card__title')?.text.trim() ??
        card.attributes['data-title']?.trim() ??
        '';
    if (name.isEmpty) continue;
    channels.putIfAbsent(id, () => Channel(id: id, name: name));
  }
  final list = channels.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}
