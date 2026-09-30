import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProductRatingsGrid extends StatelessWidget {
  const ProductRatingsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.horizontalPadding, 0,
          AppConstants.horizontalPadding, 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: const [
          _RatingItem(label: 'Daily Wear', rating: 8.0),
          _RatingItem(label: 'Durability', rating: 9.0),
          _RatingItem(label: 'Exclusivity', rating: 8.0),
          _RatingItem(label: 'Reworkability', rating: 5.0),
        ],
      ),
    );
  }
}

class _RatingItem extends StatelessWidget {
  final String label;
  final double rating;
  const _RatingItem({required this.label, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        SizedBox(
          width: 46,
          height: 46,
          child: CustomPaint(
            painter: _RatingPainter(rating: rating / 10),
            child: Center(
              child: Text(
                rating.toInt().toString(),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
              Text('Rating ${rating.toStringAsFixed(1)}/10',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary, fontSize: 10)),
            ]),
      ]),
    );
  }
}

class _RatingPainter extends CustomPainter {
  final double rating; // 0.0–1.0
  const _RatingPainter({required this.rating});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 3;

    final bg = Paint()
      ..color = AppColors.neutral200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(c, r, bg);

    final fgColor = rating >= 0.7
        ? AppColors.success
        : (rating >= 0.5 ? AppColors.gold : AppColors.error);
    final fg = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * rating,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RatingPainter old) => old.rating != rating;
}
