import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, TextEditingValue, TextSelection;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ─── Public widget ────────────────────────────────────────────────────────────

class CreditCardInput extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController cardNumberController;
  final TextEditingController expiryController;
  final TextEditingController cvcController;
  final ValueChanged<bool> onCompleteChanged;

  const CreditCardInput({
    super.key,
    required this.nameController,
    required this.cardNumberController,
    required this.expiryController,
    required this.cvcController,
    required this.onCompleteChanged,
  });

  @override
  State<CreditCardInput> createState() => _CreditCardInputState();
}

class _CreditCardInputState extends State<CreditCardInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  final _cvcFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);
    _cvcFocus.addListener(_onCvcFocus);
    widget.cardNumberController.addListener(_check);
    widget.expiryController.addListener(_check);
    widget.cvcController.addListener(_check);
  }

  void _onCvcFocus() {
    if (_cvcFocus.hasFocus) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() {});
  }

  void _check() {
    final num = widget.cardNumberController.text.replaceAll(' ', '');
    final exp = widget.expiryController.text;
    final cvc = widget.cvcController.text;
    widget.onCompleteChanged(
        num.length >= 13 && exp.length == 5 && cvc.length >= 3);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _cvcFocus.dispose();
    widget.cardNumberController.removeListener(_check);
    widget.expiryController.removeListener(_check);
    widget.cvcController.removeListener(_check);
    super.dispose();
  }

  // ── Derived display values ────────────────────────────────────────────────

  String get _displayNumber {
    final digits = widget.cardNumberController.text
        .replaceAll(' ', '')
        .padRight(16, '•');
    String g(int n) => digits.substring(n, n + 4);
    return '${g(0)}  ${g(4)}  ${g(8)}  ${g(12)}';
  }

  String get _displayExpiry {
    final v = widget.expiryController.text;
    return v.isEmpty ? 'MM / YY' : v;
  }

  String get _displayName {
    final v = widget.nameController.text.trim();
    return v.isEmpty ? 'FULL NAME' : v.toUpperCase();
  }

  _CardBrand get _brand {
    final n = widget.cardNumberController.text.replaceAll(' ', '');
    if (n.startsWith('4')) return _CardBrand.visa;
    if (n.startsWith('5') || n.startsWith('2')) return _CardBrand.mastercard;
    if (n.startsWith('3')) return _CardBrand.amex;
    return _CardBrand.unknown;
  }

  LinearGradient get _gradient {
    switch (_brand) {
      case _CardBrand.visa:
        return const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case _CardBrand.mastercard:
        return const LinearGradient(
          colors: [Color(0xFF6A0036), Color(0xFF880E4F), Color(0xFF4A148C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case _CardBrand.amex:
        return const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF006064)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case _CardBrand.unknown:
        return const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1E3A5F), Color(0xFF0A2540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated flip card
        AnimatedBuilder(
          animation: _flipAnim,
          builder: (_, __) {
            final angle = _flipAnim.value * pi;
            final showBack = angle > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _CardBack(
                        gradient: _gradient,
                        cvc: widget.cvcController.text,
                      ),
                    )
                  : _CardFront(
                      gradient: _gradient,
                      displayNumber: _displayNumber,
                      displayExpiry: _displayExpiry,
                      displayName: _displayName,
                      brand: _brand,
                    ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Card number
        _CardInputField(
          label: 'Card Number',
          controller: widget.cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [_CardNumberFormatter()],
          prefixIcon: Icons.credit_card_outlined,
          maxLength: 19,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        // Expiry + CVC row
        Row(
          children: [
            Expanded(
              child: _CardInputField(
                label: 'MM / YY',
                controller: widget.expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [_ExpiryFormatter()],
                maxLength: 5,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CardInputField(
                label: 'CVC',
                controller: widget.cvcController,
                keyboardType: TextInputType.number,
                focusNode: _cvcFocus,
                maxLength: 4,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Security note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Secured by Stripe · 256-bit SSL encrypted',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

enum _CardBrand { visa, mastercard, amex, unknown }

// ─── Card Front ───────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final LinearGradient gradient;
  final String displayNumber;
  final String displayExpiry;
  final String displayName;
  final _CardBrand brand;

  const _CardFront({
    required this.gradient,
    required this.displayNumber,
    required this.displayExpiry,
    required this.displayName,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chip + brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _ChipWidget(),
                    _BrandLogo(brand: brand),
                  ],
                ),
                const Spacer(),
                // Card number
                Text(
                  displayNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Holder + expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 8,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 8,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayExpiry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Back ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final LinearGradient gradient;
  final String cvc;

  const _CardBack({required this.gradient, required this.cvc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          // Magnetic strip
          Container(height: 42, color: const Color(0xFF111111)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Signature strip
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ''.padRight(34, '~'),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // CVC box
                Column(
                  children: [
                    Text(
                      'CVC',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 58,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cvc.isEmpty ? '•••' : cvc,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gold Chip ────────────────────────────────────────────────────────────────

class _ChipWidget extends StatelessWidget {
  const _ChipWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8CA5A), Color(0xFFC0960E), Color(0xFFE0BB45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(height: 1, color: Colors.black26),
          Container(height: 1, color: Colors.black26),
          Container(height: 1, color: Colors.black26),
        ],
      ),
    );
  }
}

// ─── Brand Logo ───────────────────────────────────────────────────────────────

class _BrandLogo extends StatelessWidget {
  final _CardBrand brand;
  const _BrandLogo({required this.brand});

  @override
  Widget build(BuildContext context) {
    switch (brand) {
      case _CardBrand.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        );
      case _CardBrand.mastercard:
        return SizedBox(
          width: 50,
          height: 30,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEB001B),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CardBrand.amex:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'AMEX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        );
      case _CardBrand.unknown:
        return Icon(
          Icons.credit_card,
          color: Colors.white.withValues(alpha: 0.35),
          size: 28,
        );
    }
  }
}

// ─── Card Input Field ─────────────────────────────────────────────────────────

class _CardInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;

  const _CardInputField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.prefixIcon,
    this.maxLength,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      focusNode: focusNode,
      textInputAction: textInputAction,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textMuted, size: 18)
            : null,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// ─── Formatters ───────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) return oldValue;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) return oldValue;
    final formatted = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
