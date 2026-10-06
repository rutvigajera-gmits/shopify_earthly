import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.chatBubbleBot,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(index: i, ctrl: _ctrl)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.chatAvatar,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.auto_awesome,
            color: AppColors.gold, size: 16),
      );
}

class _Dot extends StatelessWidget {
  final int index;
  final AnimationController ctrl;
  const _Dot({required this.index, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final phase = (ctrl.value - index * 0.2).clamp(0.0, 1.0);
        final opacity =
            (0.3 + 0.7 * (1 - (phase - 0.5).abs() * 2)).clamp(0.3, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.neutral500.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
