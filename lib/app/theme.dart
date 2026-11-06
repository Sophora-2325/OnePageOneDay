import 'package:flutter/material.dart';

/// 设计 token：与 verification/figma-tokens.json 一一对应。
/// 红只表示批改错误，黄只表示定位引文，绿只表示正确。
@immutable
class Cet6Colors extends ThemeExtension<Cet6Colors> {
  const Cet6Colors({
    required this.bg,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.lineSoft,
    required this.red,
    required this.redSoft,
    required this.green,
    required this.greenSoft,
    required this.blue,
    required this.blueSoft,
    required this.marker,
    required this.markerSoft,
    required this.tabIdle,
    required this.onAccent,
  });

  final Color bg;
  final Color paper;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color line;
  final Color lineSoft;
  final Color red;
  final Color redSoft;
  final Color green;
  final Color greenSoft;
  final Color blue;
  final Color blueSoft;
  final Color marker;
  final Color markerSoft;
  final Color tabIdle;

  /// 蓝 / 红 / 绿填充上的前景色。深色主题下语义色都很亮，
  /// 必须取深色前景，禁止组件硬编码 Colors.white。
  final Color onAccent;

  static const light = Cet6Colors(
    bg: Color(0xFFE6EAEE),
    paper: Color(0xFFFCFDFE),
    ink: Color(0xFF17222E),
    inkSoft: Color(0xFF33414F),
    muted: Color(0xFF586571),
    line: Color(0xFFC9D2DA),
    lineSoft: Color(0xFFE2E8ED),
    red: Color(0xFFB92D2D),
    redSoft: Color(0xFFFBEAEA),
    green: Color(0xFF1D6A56),
    greenSoft: Color(0xFFE6F2ED),
    blue: Color(0xFF2C5F87),
    blueSoft: Color(0xFFEAF1F6),
    marker: Color(0xFFF4D35E),
    markerSoft: Color(0xFFFFF1B8),
    tabIdle: Color(0xFF586571),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = Cet6Colors(
    bg: Color(0xFF141B22),
    paper: Color(0xFF1C252E),
    ink: Color(0xFFE9EEF2),
    inkSoft: Color(0xFFC2CDD6),
    muted: Color(0xFF8E9BA6),
    line: Color(0xFF33414C),
    lineSoft: Color(0xFF26323C),
    red: Color(0xFFE8776F),
    redSoft: Color(0xFF3A2222),
    green: Color(0xFF6FC5A5),
    greenSoft: Color(0xFF1C3229),
    blue: Color(0xFF7BB2DC),
    blueSoft: Color(0xFF1E2E3B),
    marker: Color(0xFFE8C24D),
    markerSoft: Color(0xFF4A3E18),
    tabIdle: Color(0xFF8E9BA6),
    onAccent: Color(0xFF141B22),
  );

  @override
  Cet6Colors copyWith() => this;

  @override
  Cet6Colors lerp(Cet6Colors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension Cet6Context on BuildContext {
  Cet6Colors get c => Theme.of(this).extension<Cet6Colors>()!;
}

class AppSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const page = 20.0;
}

class AppRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
}

/// 字阶下限：全库禁止 fontSize < 12，弱信息靠 c.muted 与字重区分。
class AppType {
  static const double min = 12;
}

/// 英文阅读正文、范文：衬线 16/26。
const readingFont = 'serif';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? Cet6Colors.light : Cet6Colors.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.blue,
    onPrimary: c.onAccent,
    secondary: c.blue,
    onSecondary: c.onAccent,
    error: c.red,
    onError: c.onAccent,
    surface: c.paper,
    onSurface: c.ink,
    surfaceContainerHighest: c.lineSoft,
    outline: c.line,
    outlineVariant: c.lineSoft,
  );

  const tabular = [FontFeature.tabularFigures()];
  final text = TextTheme(
    headlineSmall: TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w700, color: c.ink),
    titleMedium: TextStyle(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w600, color: c.ink),
    titleSmall: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, color: c.ink),
    bodyMedium: TextStyle(fontSize: 15, height: 24 / 15, color: c.ink),
    bodyLarge: TextStyle(fontFamily: readingFont, fontSize: 16, height: 26 / 16, color: c.ink),
    labelSmall: TextStyle(fontSize: 12, height: 18 / 12, color: c.muted, letterSpacing: 0),
    labelLarge: TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, fontFeatures: tabular, color: c.ink),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    textTheme: text,
    extensions: [c],
    dividerColor: c.line,
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.paper,
      indicatorColor: c.blueSoft,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          color: s.contains(WidgetState.selected) ? c.blue : c.tabIdle,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.blue : c.tabIdle),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.paper,
      hintStyle: TextStyle(color: c.muted, fontSize: 13),
      contentPadding: const EdgeInsets.all(AppSpace.s3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: c.blue, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: c.marker.withValues(alpha: 0.55),
      cursorColor: c.blue,
      selectionHandleColor: c.blue,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.paper, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.paper),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.paper),
  );
}
