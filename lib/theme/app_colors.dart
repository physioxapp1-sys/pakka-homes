import 'package:flutter/material.dart';

/// Navy and green.
///
/// The names stay generic (primary, textSecondary...) so a repaint is this
/// file alone - every other screen reads these rather than hard-coding a
/// colour.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF123F67);
  static const green = Color(0xFF087447);
  static const orange = Color(0xFFDE791B);
  static const purple = Color(0xFF7040B7);
  static const blue = Color(0xFF1765A8);

  static const primary = green;
  static const primaryLight = Color(0xFF0E9A5E);

  static const background = Color(0xFFF7FAFD);
  static const cardBorder = Color(0xFFDCEAF7);

  static const textPrimary = navy;
  static const textSecondary = Color(0xFF647286);

  static const tileGreen = Color(0xFFE9F7EF);
  static const tileOrange = Color(0xFFFFF3E2);
  static const tilePurple = Color(0xFFF2EDFF);
  static const tileBlue = Color(0xFFE5F5FD);

  static const emergencyRed = Color(0xFFD9534F);

  /// The logo's magenta, sampled from the sign itself.
  ///
  /// It marks shopping and nothing else: how many things are in a cart, and
  /// how much is off a price. That is the logo's own subject - a trolley in a
  /// house - so the one place the brand colour appears is the place it is
  /// about. Green stays for go and done, navy for structure, emergencyRed for
  /// what has actually gone wrong. Reach for one of those before adding a
  /// fourth meaning to this.
  static const magenta = Color(0xFF931C45);
  static const accent = magenta;
  static const tileMagenta = Color(0xFFFBEAF0);
}
