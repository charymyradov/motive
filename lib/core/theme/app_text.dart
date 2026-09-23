import 'package:flutter/material.dart';

/// The three type families of the design.
///
/// `letterSpacing` values are given in `em` like the prototype CSS and
/// converted to logical pixels here.
abstract final class AppText {
  static const _serif = 'InstrumentSerif';
  static const _sans = 'Manrope';
  static const _mono = 'JetBrainsMono';

  static TextStyle serif(
    double size, {
    Color? color,
    bool italic = false,
    double height = 1.0,
    double letterSpacing = -0.005,
  }) =>
      TextStyle(
        fontFamily: _serif,
        fontSize: size,
        fontWeight: FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: height,
        letterSpacing: letterSpacing * size,
        color: color,
      );

  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double letterSpacing = 0,
    FontStyle fontStyle = FontStyle.normal,
  }) =>
      TextStyle(
        fontFamily: _sans,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing * size,
        color: color,
        fontStyle: fontStyle,
      );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.14,
    List<Shadow>? shadows,
  }) =>
      TextStyle(
        fontFamily: _mono,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing * size,
        color: color,
        height: 1.2,
        shadows: shadows,
      );
}
