import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A coloured band across the top of a screen, ending in a wave.
///
/// Holds whatever belongs above the content - a title row, a search field -
/// so the two read as one thing rather than a bar sitting on a bar.
class WavyHeader extends StatelessWidget {
  const WavyHeader({
    super.key,
    required this.child,
    this.color = AppColors.green,
    this.waveHeight = 26,
  });

  final Widget child;
  final Color color;

  /// How deep the wave dips. The band reserves this much extra at the bottom
  /// so the wave never cuts into whatever the child's last row is.
  final double waveHeight;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(waveHeight),
      child: Container(
        width: double.infinity,
        color: color,
        padding: EdgeInsets.only(bottom: waveHeight + 10),
        child: SafeArea(bottom: false, child: child),
      ),
    );
  }
}

/// Two arcs, one down and one up, so the edge reads as a wave rather than as
/// a single scoop. The control points run past the bottom on purpose: that is
/// what gives the curve its belly instead of a shallow sag.
class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper(this.waveHeight);

  final double waveHeight;

  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    final crest = h - waveHeight;

    return Path()
      ..lineTo(0, crest)
      ..quadraticBezierTo(w * 0.22, crest + waveHeight * 1.5,
          w * 0.5, crest + waveHeight * 0.45)
      ..quadraticBezierTo(w * 0.78, crest - waveHeight * 0.65,
          w, crest + waveHeight * 0.55)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) =>
      oldClipper.waveHeight != waveHeight;
}
