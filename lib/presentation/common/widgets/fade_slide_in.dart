import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fades and slides a child widget in from a slight downward offset.
/// Use [delay] for staggered grid/list entrances.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: duration, curve: Curves.easeOut);
  }
}
