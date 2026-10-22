import 'package:intl/intl.dart';

const _months = <String, int>{
  'jan': 1,
  'january': 1,
  'feb': 2,
  'february': 2,
  'mar': 3,
  'march': 3,
  'apr': 4,
  'april': 4,
  'may': 5,
  'jun': 6,
  'june': 6,
  'jul': 7,
  'july': 7,
  'aug': 8,
  'august': 8,
  'sep': 9,
  'sept': 9,
  'september': 9,
  'oct': 10,
  'october': 10,
  'nov': 11,
  'november': 11,
  'dec': 12,
  'december': 12,
};

DateTime? parseScheduleDate(String raw) {
  final text = raw.toLowerCase().replaceAll(',', ' ');
  final monthFirst = RegExp(r'([a-z]+)\s+(\d{1,2})\s+(\d{4})').firstMatch(text);
  if (monthFirst != null) {
    final month = _months[monthFirst.group(1)!];
    if (month != null) {
      return DateTime.utc(
        int.parse(monthFirst.group(3)!),
        month,
        int.parse(monthFirst.group(2)!),
      );
    }
  }
  final dayFirst = RegExp(
    r'(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\s+(\d{4})',
  ).firstMatch(text);
  if (dayFirst != null) {
    final month = _months[dayFirst.group(2)!];
    if (month != null) {
      return DateTime.utc(
        int.parse(dayFirst.group(3)!),
        month,
        int.parse(dayFirst.group(1)!),
      );
    }
  }
  return null;
}

DateTime _lastSundayUtc(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0);
  return lastDay.subtract(Duration(days: lastDay.weekday % 7));
}

bool isUkSummerTime(DateTime utc) {
  final start = _lastSundayUtc(utc.year, 3).add(const Duration(hours: 1));
  final end = _lastSundayUtc(utc.year, 10).add(const Duration(hours: 1));
  return !utc.isBefore(start) && utc.isBefore(end);
}

int ukOffsetHours(DateTime utc) => isUkSummerTime(utc) ? 1 : 0;

/// Converts a wall-clock time published by the source (Europe/London) to the
/// device's local time zone.
DateTime ukWallClockToLocal(
  int year,
  int month,
  int day,
  int hour,
  int minute,
) {
  final approximateUtc = DateTime.utc(year, month, day, hour, minute);
  final firstGuess = approximateUtc.subtract(
    Duration(hours: ukOffsetHours(approximateUtc)),
  );
  final corrected = approximateUtc.subtract(
    Duration(hours: ukOffsetHours(firstGuess)),
  );
  return corrected.toLocal();
}

String formatTime(DateTime local) => DateFormat('HH:mm', 'es').format(local);

String formatDayLabel(DateTime local, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final date = DateTime(local.year, local.month, local.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final difference = date.difference(todayDate).inDays;
  if (difference == 0) return 'Hoy';
  if (difference == 1) return 'Mañana';
  final label = DateFormat('EEE d MMM', 'es').format(local);
  return _capitalize(label.replaceAll('.', ''));
}

String formatShortDate(DateTime local) => _capitalize(
  DateFormat('EEE d MMM', 'es').format(local).replaceAll('.', ''),
);

String formatLongDate(DateTime local) =>
    _capitalize(DateFormat("EEEE d 'de' MMMM", 'es').format(local));

String formatRelativeUpdate(DateTime? at) {
  if (at == null) return 'Sin actualizar';
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 60) return 'Hace un momento';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  return formatShortDate(at);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatCountdown(DateTime startsAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = startsAt.difference(current);
  if (diff.isNegative) {
    return diff.inMinutes <= -180 ? 'Finalizado' : 'En curso';
  }
  if (diff.inMinutes < 60) return 'En ${diff.inMinutes} min';
  if (diff.inHours < 24) {
    final minutes = diff.inMinutes % 60;
    return minutes == 0
        ? 'En ${diff.inHours} h'
        : 'En ${diff.inHours} h $minutes m';
  }
  return formatDayLabel(startsAt, now: current);
}
