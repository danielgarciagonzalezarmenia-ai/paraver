import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paraver/utils/time_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('parses month-first schedule dates', () {
    expect(
      parseScheduleDate('Saturday, August 15, 2026'),
      DateTime.utc(2026, 8, 15),
    );
  });

  test('parses day-first schedule dates', () {
    expect(parseScheduleDate('15 August 2026'), DateTime.utc(2026, 8, 15));
    expect(parseScheduleDate('1st September 2026'), DateTime.utc(2026, 9, 1));
  });

  test('detects UK summer time boundaries', () {
    expect(isUkSummerTime(DateTime.utc(2026, 1, 15, 12)), isFalse);
    expect(isUkSummerTime(DateTime.utc(2026, 7, 15, 12)), isTrue);
    expect(isUkSummerTime(DateTime.utc(2026, 3, 29, 0, 59)), isFalse);
    expect(isUkSummerTime(DateTime.utc(2026, 3, 29, 1)), isTrue);
  });

  test('formats countdowns with a fixed clock', () {
    final now = DateTime(2026, 8, 15, 12);
    expect(
      formatCountdown(DateTime(2026, 8, 15, 12, 25), now: now),
      'En 25 min',
    );
    expect(
      formatCountdown(DateTime(2026, 8, 15, 15, 30), now: now),
      'En 3 h 30 m',
    );
    expect(formatCountdown(DateTime(2026, 8, 15, 11), now: now), 'En curso');
    expect(formatCountdown(DateTime(2026, 8, 15, 8), now: now), 'Finalizado');
  });
}
