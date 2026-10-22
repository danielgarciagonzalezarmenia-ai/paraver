import 'package:flutter/cupertino.dart';

class Palette {
  const Palette({
    required this.isDark,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.blue,
    required this.coral,
    required this.amber,
    required this.green,
  });

  final bool isDark;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color blue;
  final Color coral;
  final Color amber;
  final Color green;

  static const dark = Palette(
    isDark: true,
    background: Color(0xFF070B12),
    backgroundAlt: Color(0xFF0A101A),
    surface: Color(0xFF101824),
    surfaceAlt: Color(0xFF16212F),
    border: Color(0x1AFFFFFF),
    text: Color(0xFFF4F7FB),
    textMuted: Color(0xFF8B97A8),
    accent: Color(0xFFD7FF3E),
    accentSoft: Color(0x2ED7FF3E),
    onAccent: Color(0xFF080D14),
    blue: Color(0xFF5B8CFF),
    coral: Color(0xFFFF5C5C),
    amber: Color(0xFFFFB648),
    green: Color(0xFF59E3A7),
  );

  static const light = Palette(
    isDark: false,
    background: Color(0xFFF4F3EE),
    backgroundAlt: Color(0xFFEDECE6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0EFE9),
    border: Color(0x16000000),
    text: Color(0xFF0A0D12),
    textMuted: Color(0xFF616B79),
    accent: Color(0xFFB9E600),
    accentSoft: Color(0x33B9E600),
    onAccent: Color(0xFF080D14),
    blue: Color(0xFF2F5BFF),
    coral: Color(0xFFE33A3A),
    amber: Color(0xFFE08A12),
    green: Color(0xFF138A5B),
  );
}

class PaletteScope extends InheritedWidget {
  const PaletteScope({super.key, required this.palette, required super.child});

  final Palette palette;

  static Palette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaletteScope>();
    return scope?.palette ?? Palette.dark;
  }

  @override
  bool updateShouldNotify(PaletteScope oldWidget) =>
      oldWidget.palette != palette;
}

extension PaletteContext on BuildContext {
  Palette get palette => PaletteScope.of(this);
}

class AppText {
  static FontWeight _weight(double value) {
    if (value >= 850) return FontWeight.w900;
    if (value >= 750) return FontWeight.w800;
    if (value >= 650) return FontWeight.w700;
    if (value >= 550) return FontWeight.w600;
    if (value >= 450) return FontWeight.w500;
    if (value >= 350) return FontWeight.w400;
    return FontWeight.w300;
  }

  static TextStyle display(
    double size, {
    double weight = 700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: size,
    height: height,
    color: color,
    letterSpacing: letterSpacing ?? -0.6,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight)],
  );

  static TextStyle body(
    double size, {
    double weight = 400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight)],
  );

  static TextStyle mono(double size, {double weight = 600, Color? color}) =>
      body(size, weight: weight, color: color, letterSpacing: -0.2).copyWith(
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );
}

class ParaVerTheme {
  static CupertinoThemeData cupertino(Palette p) {
    final textTheme = CupertinoTextThemeData(
      primaryColor: p.accent,
      textStyle: AppText.body(15, color: p.text, height: 1.35),
      navLargeTitleTextStyle: AppText.display(32, color: p.text),
      navTitleTextStyle: AppText.body(17, weight: 600, color: p.text),
      tabLabelTextStyle: AppText.body(10, weight: 600, color: p.textMuted),
      actionTextStyle: AppText.body(17, color: p.accent),
      pickerTextStyle: AppText.body(20, color: p.text),
      dateTimePickerTextStyle: AppText.body(20, color: p.text),
    );
    return CupertinoThemeData(
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primaryColor: p.accent,
      primaryContrastingColor: p.onAccent,
      barBackgroundColor: p.background.withValues(alpha: 0.92),
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
    );
  }
}
