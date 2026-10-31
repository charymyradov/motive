import 'package:flutter/material.dart';

import '../theme/motive_colors.dart';

/// A shimmering placeholder block used while content is loading.
///
/// Replaces the bare `CircularProgressIndicator` with a shape close to what is
/// about to render, so the layout does not jump when data arrives.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
    this.child,
  });

  final double? width;
  final double height;
  final double radius;

  /// Optional content drawn on top of the shimmer (e.g. a card silhouette).
  final Widget? child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [c.glass, c.glass2.withValues(alpha: .95), c.glass],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// A card-shaped skeleton, matching the feed/collection tile aspect ratio.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.aspectRatio = 5 / 7});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: aspectRatio,
        child: Skeleton(radius: 14, height: double.infinity, child: const SizedBox.expand()),
      );
}

/// Header + lines skeleton used by text-heavy screens.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.lines = 3, this.width = 160});

  final int lines;
  final double width;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: width, height: 22, radius: 10),
          const SizedBox(height: 10),
          for (var i = 0; i < lines; i++) ...[
            Skeleton(width: i.isEven ? double.infinity : width + 60, height: 12),
            const SizedBox(height: 8),
          ],
        ],
      );
}
