import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../component/loader_widget.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';

class ProductActionButtons extends StatelessWidget {
  final VoidCallback onBeginOrder;
  final bool addingToCart;

  const ProductActionButtons(
      {super.key, required this.onBeginOrder, required this.addingToCart});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: addingToCart ? null : onBeginOrder,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(32),
            ),
            alignment: Alignment.center,
            child: addingToCart
                ? const LoaderWidget(size: 22, color: Colors.white)
                : Text('Begin my order',
                    style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
      12.width,
      Expanded(
        child: GestureDetector(
          onTap: () async {
            final uri = Uri.parse(
                'https://wa.me/${AppStrings.whatsAppNumber}?text=${AppStrings.whatsAppOrderMessage}');
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.chat_outlined, size: 18, color: Colors.white),
              8.width,
              Text('WhatsApp Us',
                  style: AppTextStyles.button.copyWith(color: Colors.white)),
            ]),
          ),
        ),
      ),
    ]).paddingOnly(
      left: AppConstants.horizontalPadding,
      top: 4,
      right: AppConstants.horizontalPadding,
      bottom: 16,
    );
  }
}

class ProductDeliverySection extends StatelessWidget {
  final TextEditingController pincodeController;
  const ProductDeliverySection({super.key, required this.pincodeController});

  @override
  Widget build(BuildContext context) {
    final delivery = DateTime.now().add(const Duration(days: 21));
    final dateStr = FormatUtils.formatDate(delivery);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(color: AppColors.border),
      10.height,
      Row(children: [
        const Icon(Icons.calendar_today_outlined,
            size: 17, color: AppColors.textSecondary),
        8.width,
        Text.rich(TextSpan(children: [
          TextSpan(
              text: 'Estimated Delivery: ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          TextSpan(
              text: dateStr,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ])),
      ]),
      12.height,
      // Row(children: [
      //   Expanded(
      //     child: Container(
      //       height: 46,
      //       decoration: BoxDecoration(
      //         border: Border.all(color: AppColors.border),
      //         borderRadius: const BorderRadius.only(
      //           topLeft: Radius.circular(4),
      //           bottomLeft: Radius.circular(4),
      //         ),
      //       ),
      //       padding: const EdgeInsets.symmetric(horizontal: 12),
      //       child: TextField(
      //         controller: pincodeController,
      //         keyboardType: TextInputType.number,
      //         style: AppTextStyles.bodyMedium,
      //         decoration: InputDecoration(
      //           hintText: 'Enter your pincode',
      //           hintStyle: AppTextStyles.bodySmall
      //               .copyWith(color: AppColors.textMuted),
      //           border: InputBorder.none,
      //         ),
      //       ),
      //     ),
      //   ),
      //   GestureDetector(
      //     onTap: () {
      //       final pin = pincodeController.text.trim();
      //       if (pin.isNotEmpty) {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //             SnackBar(content: Text('Delivery available at $pin!')));
      //       }
      //     },
      //     child: Container(
      //       height: 46,
      //       padding: const EdgeInsets.symmetric(horizontal: 20),
      //       decoration: const BoxDecoration(
      //         color: AppColors.textPrimary,
      //         borderRadius: BorderRadius.only(
      //           topRight: Radius.circular(4),
      //           bottomRight: Radius.circular(4),
      //         ),
      //       ),
      //       alignment: Alignment.center,
      //       child: Text('Check',
      //           style:
      //               AppTextStyles.button.copyWith(color: Colors.white)),
      //     ),
      //   ),
      // ]),
    ]).paddingOnly(
      left: AppConstants.horizontalPadding,
      right: AppConstants.horizontalPadding,
      bottom: 16,
    );
  }
}

class ProductConsultationBanner extends StatelessWidget {
  const ProductConsultationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppConstants.horizontalPadding, 0,
          AppConstants.horizontalPadding, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.videocam_outlined,
              color: Colors.white, size: 20),
        ),
        12.width,
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book your private video',
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                Text('consultation',
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
              ]),
        ),
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse(AppStrings.consultationUrl);
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text('Schedule Now!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              )),
        ),
      ]),
    );
  }
}

class ProductPickDiamondCard extends StatelessWidget {
  const ProductPickDiamondCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppConstants.horizontalPadding, 0,
          AppConstants.horizontalPadding, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        const Icon(Icons.diamond_outlined, size: 30, color: AppColors.teal),
        12.width,
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick a Unique Diamond',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.teal, fontSize: 14)),
                3.height,
                Text(
                  'Explore rare diamonds crafted to make every design extraordinary.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ]),
        ),
        8.width,
        const Icon(Icons.arrow_forward,
            size: 18, color: AppColors.textSecondary),
      ]),
    );
  }
}
