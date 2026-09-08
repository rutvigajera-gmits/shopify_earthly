import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/shop_provider.dart';

class AnnouncementBar extends StatefulWidget {
  const AnnouncementBar({super.key});

  @override
  State<AnnouncementBar> createState() => _AnnouncementBarState();
}

class _AnnouncementBarState extends State<AnnouncementBar> {
  int _index = 0;
  Timer? _timer;
  List<String> _tracked = [];

  static const _defaults = ['BOOK YOUR STORE VISIT - ANDHERI WEST MUMBAI'];

  void _startTimer(List<String> messages) {
    _timer?.cancel();
    if (messages.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _index = (_index + 1) % messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, shop, _) {
        final messages =
            shop.announcements.isNotEmpty ? shop.announcements : _defaults;

        if (messages != _tracked) {
          _tracked = messages;
          _index = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startTimer(messages);
          });
        } else if (_timer == null && messages.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startTimer(messages);
          });
        }

        final safeIndex = _index.clamp(0, messages.length - 1);

        return Container(
          width: double.infinity,
          color: AppColors.announcementBg,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              messages[safeIndex],
              key: ValueKey('$safeIndex-${messages[safeIndex]}'),
              textAlign: TextAlign.center,
              style: AppTextStyles.announcement,
            ),
          ),
        );
      },
    );
  }
}
