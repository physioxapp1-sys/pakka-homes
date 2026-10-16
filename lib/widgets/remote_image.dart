import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Every picture the app loads from the server.
///
/// Image.network keeps what it has fetched in memory only, so closing the app
/// threw all of it away and the next open paid for the whole catalog again.
/// This caches to disk, which is the difference between a grocery aisle
/// costing a download every time and costing one once.
///
/// It exists as one widget rather than seven call sites so that the caching
/// decision - and reverting it - is a single file.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingColor = const Color(0xFFF1F6FA),
  });

  /// Null or empty means there is no picture: the fallback is drawn instead,
  /// which is also what a failed load gets. A missing image and a broken one
  /// look the same to someone holding the phone, so they look the same here.
  final String? url;
  final Widget fallback;

  final BoxFit fit;
  final double? width;
  final double? height;

  /// A flat tint while the bytes arrive. Deliberately not a spinner: a grid
  /// of twelve spinners is worse than a grid of quiet rectangles.
  final Color loadingColor;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: loadingColor,
      ),
      errorWidget: (context, _, __) => fallback,
    );
  }
}
