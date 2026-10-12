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
}
