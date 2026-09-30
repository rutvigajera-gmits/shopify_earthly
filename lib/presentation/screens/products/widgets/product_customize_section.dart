import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/product_model.dart';
import '../../../widgets/size_chart_sheet.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text('Customize', style: AppTextStyles.labelLarge),
            ),
          ),
          const SizedBox(height: 20),
          ...opts.map((opt) => _OptionSection(
                name: opt.name,
                values: opt.values,
                selectedValue: selectedOptions[opt.name] ?? '',
                onChanged: (val) => onOptionChanged(opt.name, val),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: name,
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                  if (selectedValue.isNotEmpty) ...[
                    TextSpan(
                        text: ':  ',
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                    TextSpan(
                        text: selectedValue,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        )),
                  ],
                ]),
              ),
              if (_isSize) const SizeChartLink(),
            ],
          ),
          const SizedBox(height: 10),
          if (_isMetal)
            _MetalTypePicker(
                values: values, selected: selectedValue, onChanged: onChanged)
          else if (_isSize)
            _SizeDropdown(
                values: values, selected: selectedValue, onChanged: onChanged)
          else
            _ChipPicker(
                values: values, selected: selectedValue, onChanged: onChanged),
          if (_isSize) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.radio_button_unchecked,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Price and weight will changes as per the size',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ChipPicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChipPicker(
      {required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(v,
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 13,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
        );
      }).toList(),
    );
  }
}

class _SizeDropdown extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SizeDropdown(
      {required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final eff = values.contains(selected) ? selected : values.firstOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: eff,
          isExpanded: true,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
          items: values
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _MetalTypePicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetalTypePicker(
      {required this.values, required this.selected, required this.onChanged});

  Color _color(String v) {
    final l = v.toLowerCase();
    if (l.contains('rose') || l.contains('pink')) return const Color(0xFFB87B6A);
    if (l.contains('white') || l.contains('platinum') || l.contains('silver')) {
      return const Color(0xFFCECECE);
    }
    return const Color(0xFFD4AF37);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color(v),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(1, 2))
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                v.replaceFirst(' Gold', '').replaceFirst(' gold', ''),
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
