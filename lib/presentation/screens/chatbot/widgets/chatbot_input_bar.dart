import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ChatbotInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool enabled;

  const ChatbotInputBar({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<ChatbotInputBar> createState() => _ChatbotInputBarState();
}

class _ChatbotInputBarState extends State<ChatbotInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(
        () => setState(() => _hasText = _controller.text.trim().isNotEmpty));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                cursorColor: AppColors.gold,
                decoration: const InputDecoration(
                  hintText: 'Message Ring Matchmaker',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.chatInputFill,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(color: AppColors.teal),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _hasText && widget.enabled
                    ? AppColors.gold
                    : AppColors.neutral200,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _hasText && widget.enabled ? _send : null,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: _hasText && widget.enabled
                      ? AppColors.textWhite
                      : AppColors.neutral500,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
