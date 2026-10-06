import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BotBubble extends StatelessWidget {
  final String text;
  final bool isError;

  const BotBubble({super.key, required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 56, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isError
                    ? AppColors.chatBubbleError
                    : AppColors.chatBubbleBot,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.chatAvatar,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: AppColors.gold,
        size: 16,
      ),
    );
  }
}
