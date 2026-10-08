import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../component/loader_widget.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/customer_model.dart';
import '../../common/widgets/app_header.dart';
import '../../providers/customer_provider.dart';

enum _PhotoAction { camera, gallery, remove }

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;

  bool _saving = false;

  CustomerProvider get _customerProvider => context.read<CustomerProvider>();

  @override
  void initState() {
    super.initState();
    final c = _customerProvider.customer!;
    _firstName = TextEditingController(text: c.firstName);
    _lastName  = TextEditingController(text: c.lastName);
    _phone     = TextEditingController(text: c.phone ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Profile Photo', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text('Choose how to update your photo',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              _SourceTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () => Navigator.pop(sheetCtx, _PhotoAction.camera),
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(sheetCtx, _PhotoAction.gallery),
              ),
              if (context.read<CustomerProvider>().profileImagePath != null) ...[
                const Divider(height: 1, color: AppColors.neutral200),
                _SourceTile(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  onTap: () => Navigator.pop(sheetCtx, _PhotoAction.remove),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).then((action) {
      // Called only after the sheet has fully closed — safe to launch picker.
      if (!mounted || action == null) return;
      switch (action) {
        case _PhotoAction.camera:
          _pickImage(ImageSource.camera);
        case _PhotoAction.gallery:
          _pickImage(ImageSource.gallery);
        case _PhotoAction.remove:
          _removeImage();
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null || !mounted) return;
      await _customerProvider.setProfileImagePath(picked.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not access photos. Please check permissions.')),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    await _customerProvider.setProfileImagePath(null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CustomerProvider>();
    await provider.updateProfile(
      firstName: _firstName.text.trim(),
      lastName:  _lastName.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (provider.errorMessage == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customer = provider.customer!;
    final profileImage = provider.profileImagePath != null
        ? File(provider.profileImagePath!)
        : null;
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: const AppHeader(title: 'Edit Profile', showBack: true),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _ProfileHeader(
                      customer: customer,
                      profileImage: profileImage,
                      onEditPhoto: _showImageSourceSheet,
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('PERSONAL INFORMATION'),
                    const SizedBox(height: 8),
                    _FormCard(children: [
                      _EditField(
                        label: 'First Name',
                        controller: _firstName,
                        icon: Icons.person_outline_rounded,
                        required: true,
                      ),
                      const _CardDivider(),
                      _EditField(
                        label: 'Last Name',
                        controller: _lastName,
                        icon: Icons.person_outline_rounded,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel('CONTACT'),
                    const SizedBox(height: 8),
                    _FormCard(children: [
                      _EditField(
                        label: 'Phone Number',
                        controller: _phone,
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        hint: '+91 98765 43210',
                      ),
                      const _CardDivider(),
                      _ReadOnlyField(
                        label: 'Email Address',
                        value: customer.email,
                        icon: Icons.mail_outline_rounded,
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              _SaveButton(saving: _saving, onTap: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding),
        child: Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Customer customer;
  final File? profileImage;
  final VoidCallback onEditPhoto;

  const _ProfileHeader({
    required this.customer,
    required this.profileImage,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal, Color(0xFF002B30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onEditPhoto,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1.5),
                  ),
                  child: profileImage != null
                      ? ClipOval(
                          child: Image.file(
                            profileImage!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          ),
                        )
                      : Center(
                          child: Text(
                            customer.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                ),
                // Camera badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: AppColors.teal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer.displayName,
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            customer.email,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onEditPhoto,
            child: Text(
              'Change photo',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Source picker tile ───────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22,
                color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: labelColor ?? AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.neutral200,
        indent: 52);
  }
}

// ─── Editable Field ───────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required;
  final TextInputType keyboard;
  final String? hint;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.required = false,
    this.keyboard = TextInputType.text,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  required ? '$label *' : label,
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboard,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.neutral500),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.error),
                  ),
                  validator: required
                      ? (v) => (v == null || v.trim().isEmpty)
                          ? '$label is required'
                          : null
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Read-only Field ──────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: AppColors.neutral300),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.neutral300, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.lock_outline,
                        size: 11, color: AppColors.neutral300),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.neutral300),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email address cannot be changed',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.neutral300, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;

  const _SaveButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding, 12,
          AppConstants.horizontalPadding, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: saving ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.neutral300,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const RoundedRectangleBorder(),
          ),
          child: saving
              ? const LoaderWidget(size: 22, color: Colors.white)
              : Text(
                  'SAVE CHANGES',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
