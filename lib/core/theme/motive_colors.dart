import 'package:flutter/material.dart';

/// Design tokens of the Motive UI (the CSS variables of the prototype).
///
/// Registered as a [ThemeExtension] so switching dark/light animates smoothly.
@immutable
class MotiveColors extends ThemeExtension<MotiveColors> {
  const MotiveColors({
    required this.bg,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.glass,
    required this.glass2,
    required this.line,
    required this.blob1,
    required this.blob2,
    required this.blob3,
    required this.bar,
    required this.shadow,
    required this.solid,
    required this.onSolid,
  });

  final Color bg;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color glass;
  final Color glass2;
  final Color line;
  final Color blob1;
  final Color blob2;
  final Color blob3;
  final Color bar;
  final Color shadow;
  final Color solid;
  final Color onSolid;

  static const dark = MotiveColors(
    bg: Color(0xFF08070F),
    ink: Color(0xFFF4F2FB),
    ink2: Color(0xB8F4F2FB),
    ink3: Color(0x80F4F2FB),
    glass: Color(0x0EFFFFFF),
    glass2: Color(0x1AFFFFFF),
    line: Color(0x1CFFFFFF),
    blob1: Color(0xFF5B2BFF),
    blob2: Color(0xFF008CFF),
    blob3: Color(0xFFFF2D95),
    bar: Color(0x9E0C0A18),
    shadow: Color(0x99000000),
    solid: Color(0xFFF4F2FB),
    onSolid: Color(0xFF0B0A14),
  );

  static const light = MotiveColors(
    bg: Color(0xFFF2F1F7),
    ink: Color(0xFF15131F),
    ink2: Color(0xB815131F),
    ink3: Color(0x8015131F),
    glass: Color(0x8CFFFFFF),
    glass2: Color(0xCCFFFFFF),
    line: Color(0x1A15131F),
    blob1: Color(0xFFB7A2FF),
    blob2: Color(0xFF8FD8FF),
    blob3: Color(0xFFFFB0D4),
    bar: Color(0xA8FFFFFF),
    shadow: Color(0x40463288),
    solid: Color(0xFF15131F),
    onSolid: Color(0xFFF4F2FB),
  );

  @override
  MotiveColors copyWith({
    Color? bg,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? glass,
    Color? glass2,
    Color? line,
    Color? blob1,
    Color? blob2,
    Color? blob3,
    Color? bar,
    Color? shadow,
    Color? solid,
    Color? onSolid,
  }) {
    return MotiveColors(
      bg: bg ?? this.bg,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      glass: glass ?? this.glass,
      glass2: glass2 ?? this.glass2,
      line: line ?? this.line,
      blob1: blob1 ?? this.blob1,
      blob2: blob2 ?? this.blob2,
      blob3: blob3 ?? this.blob3,
      bar: bar ?? this.bar,
      shadow: shadow ?? this.shadow,
      solid: solid ?? this.solid,
      onSolid: onSolid ?? this.onSolid,
    );
  }

  @override
  MotiveColors lerp(ThemeExtension<MotiveColors>? other, double t) {
    if (other is! MotiveColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return MotiveColors(
      bg: l(bg, other.bg),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      glass: l(glass, other.glass),
      glass2: l(glass2, other.glass2),
      line: l(line, other.line),
      blob1: l(blob1, other.blob1),
      blob2: l(blob2, other.blob2),
      blob3: l(blob3, other.blob3),
      bar: l(bar, other.bar),
      shadow: l(shadow, other.shadow),
      solid: l(solid, other.solid),
      onSolid: l(onSolid, other.onSolid),
    );
  }
}

extension MotiveColorsX on BuildContext {
  MotiveColors get mc => Theme.of(this).extension<MotiveColors>()!;
}

/// Fixed accent colors that do not change with the theme.
abstract final class Palette {
  static const holds = Color(0xFF3EE6A0);
  static const nope = Color(0xFFFF5F7E);
  static const nopeSoft = Color(0xFFFF8FA3);
  static const accent = Color(0xFFC77DFF);
  static const warn = Color(0xFFFFC857);
  static const xpA = Color(0xFF9D7BFF);
  static const xpB = Color(0xFF46D4FF);
  static const overlayInk = Color(0xFFF4F2FB);
  static const overlayScrim = Color(0xBB05040C);

  static const flame = RadialGradient(
    center: Alignment(-0.2, -0.3),
    colors: [Color(0xFFFFE27A), Color(0xFFFF7A00), Color(0xFFFF3D6E)],
    stops: [0, .6, 1],
  );
}
