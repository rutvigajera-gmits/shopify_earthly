import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class SuggestionChipsBar extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const SuggestionChipsBar({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: suggestions
            .map((s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.background,
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
