import 'package:flutter/material.dart';

String stripEmoji(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final isEmoji =
        (rune >= 0x1F000 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
        rune == 0xFE0F ||
        rune == 0x200D ||
        rune == 0x20E3;
    if (!isEmoji) buffer.writeCharCode(rune);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class SportStyle {
  const SportStyle({
    required this.key,
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String key;
  final String label;
  final IconData icon;
  final List<Color> colors;
}

const _styles = <String, SportStyle>{
  'soccer': SportStyle(
    key: 'soccer',
    label: 'Fútbol',
    icon: Icons.sports_soccer_rounded,
    colors: [Color(0xFF21D07A), Color(0xFF0B7A55)],
  ),
  'basketball': SportStyle(
    key: 'basketball',
    label: 'Básquet',
    icon: Icons.sports_basketball_rounded,
    colors: [Color(0xFFFF9A3C), Color(0xFFB33A12)],
  ),
  'nfl': SportStyle(
    key: 'nfl',
    label: 'NFL',
    icon: Icons.sports_football_rounded,
    colors: [Color(0xFF5B8CFF), Color(0xFF243C9E)],
  ),
  'tennis': SportStyle(
    key: 'tennis',
    label: 'Tenis',
    icon: Icons.sports_tennis_rounded,
    colors: [Color(0xFFD7FF3E), Color(0xFF5F8E00)],
  ),
  'combat': SportStyle(
    key: 'combat',
    label: 'Combate',
    icon: Icons.sports_mma_rounded,
    colors: [Color(0xFFFF5C7A), Color(0xFF7A1230)],
  ),
  'motorsport': SportStyle(
    key: 'motorsport',
    label: 'Motor',
    icon: Icons.sports_motorsports_rounded,
    colors: [Color(0xFFFF6A3D), Color(0xFF8A1B0B)],
  ),
  'hockey': SportStyle(
    key: 'hockey',
    label: 'Hockey',
    icon: Icons.sports_hockey_rounded,
    colors: [Color(0xFF4AD8F5), Color(0xFF135C93)],
  ),
  'cricket': SportStyle(
    key: 'cricket',
    label: 'Cricket',
    icon: Icons.sports_cricket_rounded,
    colors: [Color(0xFF9BE564), Color(0xFF2B6B35)],
  ),
  'golf': SportStyle(
    key: 'golf',
    label: 'Golf',
    icon: Icons.sports_golf_rounded,
    colors: [Color(0xFF8DE37A), Color(0xFF28633A)],
  ),
  'other': SportStyle(
    key: 'other',
    label: 'Más deportes',
    icon: Icons.sports_rounded,
    colors: [Color(0xFF8E7CFF), Color(0xFF3B2E8F)],
  ),
  'ppv': SportStyle(
    key: 'ppv',
    label: 'PPV',
    icon: Icons.bolt_rounded,
    colors: [Color(0xFFD7FF3E), Color(0xFF3B6BFF)],
  ),
};

SportStyle sportStyleFor(String category) {
  final c = stripEmoji(category).toLowerCase();
  if (c.contains('ppv') || c.contains('upcoming') || c.contains('live now')) {
    return _styles['ppv']!;
  }
  if (c.contains('soccer') || c.contains('fútbol') || c.contains('futbol')) {
    return _styles['soccer']!;
  }
  if (c.contains('football') || c.contains('nfl') || c.contains('ncaaf')) {
    return _styles['nfl']!;
  }
  if (c.contains('basket') || c.contains('nba') || c.contains('euroleague')) {
    return _styles['basketball']!;
  }
  if (c.contains('tennis')) return _styles['tennis']!;
  if (c.contains('mma') ||
      c.contains('wrestling') ||
      c.contains('boxing') ||
      c.contains('ufc')) {
    return _styles['combat']!;
  }
  if (c.contains('motor') ||
      c.contains('racing') ||
      c.contains('formula') ||
      c.contains('nascar')) {
    return _styles['motorsport']!;
  }
  if (c.contains('hockey') || c.contains('nhl')) return _styles['hockey']!;
  if (c.contains('cricket')) return _styles['cricket']!;
  if (c.contains('golf')) return _styles['golf']!;
  return _styles['other']!;
}

List<SportStyle> get featuredSports => [
  _styles['soccer']!,
  _styles['basketball']!,
  _styles['nfl']!,
  _styles['tennis']!,
  _styles['combat']!,
  _styles['motorsport']!,
  _styles['hockey']!,
];
