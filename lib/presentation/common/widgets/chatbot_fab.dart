import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/screens/chatbot/chatbot_sheet.dart';

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showChatbotSheet(context),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.chatFab,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 22),
      ),
    );
  }
}
