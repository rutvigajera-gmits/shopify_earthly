import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/product_model.dart';
import '../../../common/widgets/size_chart_sheet.dart';

class ProductCustomizeSection extends StatelessWidget {
  final Product product;
  final Map<String, String> selectedOptions;
  final void Function(String, String) onOptionChanged;

  const ProductCustomizeSection({
    super.key,
    required this.product,
    required this.selectedOptions,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final opts = [
      ...product.realOptions,
      if (!product.realOptions.any((o) => o.name.toLowerCase().contains('metal')))
        const ProductOption(
            name: 'Metal Type',
            values: ['Yellow Gold', 'Rose Gold', 'White Gold']),
    ];
    if (opts.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.border),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                10.width,
                Text('Customize', style: AppTextStyles.headlineSmall),
              ]),
              24.height,
              ...List.generate(opts.length, (idx) {
                final opt = opts[idx];
                return Column(
                  children: [
                    _OptionSection(
                      name: opt.name,
                      values: opt.values,
                      selectedValue: selectedOptions[opt.name] ?? '',
                      onChanged: (val) => onOptionChanged(opt.name, val),
                    ),
                    if (idx < opts.length - 1)
                      const Divider(height: 1, color: AppColors.border),
                    if (idx < opts.length - 1) 20.height,
                  ],
                );
              }),
              8.height,
            ],
          ).paddingOnly(
            left: AppConstants.horizontalPadding,
            top: 22,
            right: AppConstants.horizontalPadding,
            bottom: 4,
          ),
        ],
      ),
    );
  }
}

// ─── Option Section ───────────────────────────────────────────────────────────

class _OptionSection extends StatelessWidget {
  final String name;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _OptionSection({
    required this.name,
    required this.values,
    required this.selectedValue,
    required this.onChanged,
  });

  bool get _isMetal => name.toLowerCase().contains('metal');
  bool get _isSize => name.toLowerCase() == 'size';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              name.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(children: [
              if (selectedValue.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedValue,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (_isSize) ...[
                10.width,
                const SizeChartLink(),
              ],
            ]),
          ],
        ),
        14.height,
        if (_isMetal)
          _MetalTypePicker(
              values: values, selected: selectedValue, onChanged: onChanged)
        else if (_isSize)
          _SizeChipRow(
              values: values, selected: selectedValue, onChanged: onChanged)
        else
          _ChipPicker(
              values: values, selected: selectedValue, onChanged: onChanged),
        if (_isSize) ...[
          8.height,
          Row(children: [
            const Icon(Icons.info_outline,
                size: 11, color: AppColors.textMuted),
            4.width,
            Text(
              'Price and weight change with size',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ]),
        ],
      ],
    ).paddingOnly(bottom: 20);
  }
}

// ─── Chip Picker ──────────────────────────────────────────────────────────────

class _ChipPicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChipPicker(
      {required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final active = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.textPrimary : Colors.white,
              border: Border.all(
                color: active ? AppColors.textPrimary : AppColors.border,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              v,
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 13,
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Size Chip Row ────────────────────────────────────────────────────────────

class _SizeChipRow extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SizeChipRow(
      {required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => 8.width,
        itemBuilder: (_, i) {
          final v = values[i];
          final active = v == selected;
          return GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.textPrimary : Colors.white,
                border: Border.all(
                  color: active ? AppColors.textPrimary : AppColors.border,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                v,
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 13,
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Metal Type Picker ────────────────────────────────────────────────────────

class _MetalTypePicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetalTypePicker(
      {required this.values, required this.selected, required this.onChanged});

  LinearGradient _gradient(String v) {
    final l = v.toLowerCase();
    if (l.contains('rose') || l.contains('pink')) {
      return const LinearGradient(
        colors: [Color(0xFFF0C4B8), Color(0xFF9E5B4A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (l.contains('white') || l.contains('platinum') || l.contains('silver')) {
      return const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFAAAAAA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFFFE57A), Color(0xFFB8860B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  bool _useDarkCheck(String v) {
    final l = v.toLowerCase();
    return l.contains('yellow') || l.contains('white') || l.contains('platinum');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final active = v == selected;
        final label = v
            .replaceAll(' Gold', '')
            .replaceAll(' gold', '')
            .replaceAll('Platinum', 'Plat.');
        return GestureDetector(
          onTap: () => onChanged(v),
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(active ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.textPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _gradient(v),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: active
                    ? Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: _useDarkCheck(v)
                            ? const Color(0xFF5A3E00)
                            : Colors.white70,
                      )
                    : null,
              ),
            ),
            6.height,
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: AppTextStyles.labelSmall.copyWith(
                color: active ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ]).paddingOnly(right: 20),
        );
      }).toList(),
    );
  }
}
