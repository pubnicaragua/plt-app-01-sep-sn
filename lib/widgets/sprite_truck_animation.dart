import 'package:flutter/material.dart';

/// Displays the supplied vehicle asset without cropping or altering its frames.
/// If the asset is an animated GIF, Flutter's Image widget plays it natively.
class SpriteTruckAnimation extends StatelessWidget {
  const SpriteTruckAnimation({
    super.key,
    required this.asset,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.local_shipping_rounded,
          color: Colors.white70,
          size: 100,
        ),
      );
}
