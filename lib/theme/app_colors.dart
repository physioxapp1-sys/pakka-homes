import 'package:flutter/material.dart';

/// Navy and amber, matching the gold house icon far better than the green
/// this started with.
///
/// The names are kept deliberately generic (primary, textSecondary...) so a
/// repaint is this file alone - every other screen reads these rather than
/// hard-coding a colour.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF102A43);
  static const orange = Color(0xFFFFA800);
  static const darkOrange = Color(0xFFF28C00);
  static const blue = Color(0xFF1976D2);
  static const green = Color(0xFF159570);
  static const indigo = Color(0xFF5B5BD6);

  static const primary = navy;
  static const primaryLight = Color(0xFF1D4E6D);

  static const background = Color(0xFFF7F9FC);
  static const cardBorder = Color(0x14000000);

  static const textPrimary = navy;
  static const textSecondary = Color(0xFF6B7C93);

  static const lightGreen = Color(0xFFE9F8F3);
  static const lightBlue = Color(0xFFEAF2FF);
  static const lightPurple = Color(0xFFF0EEFF);
  static const lightOrange = Color(0xFFFFF1E7);

  static const emergencyRed = Color(0xFFD9534F);
}
