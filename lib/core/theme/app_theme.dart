import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motive_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(MotiveColors.dark, Brightness.dark);
  static ThemeData light() => _build(MotiveColors.light, Brightness.light);

  static ThemeData _build(MotiveColors c, Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B2CFF),
      brightness: b,
    ).copyWith(surface: c.bg, onSurface: c.ink, primary: c.solid, onPrimary: c.onSolid);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'Manrope',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [c],
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Palette.accent,
        selectionColor: Color(0x55C77DFF),
        selectionHandleColor: Palette.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.solid,
        contentTextStyle: TextStyle(fontFamily: 'Manrope', color: c.onSolid, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF15131F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF110F1C) : const Color(0xFFF7F6FB),
        showDragHandle: true,
        dragHandleColor: c.ink3,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
    );
  }
}
