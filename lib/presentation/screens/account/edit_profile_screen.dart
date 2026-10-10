import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:demo_earthly/core/utils/common.dart';
import 'package:demo_earthly/core/utils/images.dart';
import 'package:demo_earthly/core/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
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

  late Country selectedCountry;
  Country? selectedCountryCode;
  final ValueNotifier<bool> _valueNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get valueNotifier => _valueNotifier;
  late final TextEditingController mobileCont;
  late final FocusNode mobileFocus;
  late final FocusNode passwordFocus;

  CustomerProvider get _customerProvider => context.read<CustomerProvider>();

  @override
  void initState() {
    super.initState();
    final c = _customerProvider.customer!;
    _firstName = TextEditingController(text: c.firstName);
    _lastName  = TextEditingController(text: c.lastName);
    _phone     = TextEditingController(text: c.phone ?? '');
    mobileCont = TextEditingController(text: c.phone ?? '');
    mobileFocus = FocusNode();
    passwordFocus = FocusNode();
    selectedCountry = CountryParser.tryParseCountryCode('IN') ??
        CountryService().getAll().first;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    mobileCont.dispose();
    mobileFocus.dispose();
    passwordFocus.dispose();
    _valueNotifier.dispose();
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
                    24.height,
                    _sectionLabel('PERSONAL INFORMATION'),
                    12.height,
                    AppTextField(
                      controller: _firstName,
                      textFieldType: TextFieldType.NAME,
                      decoration: inputDecoration(
                        context,
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ).paddingSymmetric(horizontal: AppConstants.horizontalPadding),
                    14.height,
                    AppTextField(
                      controller: _lastName,
                      decoration: inputDecoration(
                        context,
                        labelText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ), 
                      textFieldType: TextFieldType.NAME,
                    ).paddingSymmetric(horizontal: AppConstants.horizontalPadding),
                    24.height,
                    _sectionLabel('CONTACT'),
                    12.height,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country code ...
                        Container(
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: ValueListenableBuilder(
                              valueListenable: _valueNotifier,
                              builder: (context, value, child) => Row(
                                children: [
                                  Text(
                                    "+${selectedCountry.phoneCode}",
                                    style: primaryTextStyle(size: 12),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: textSecondaryColorGlobal,
                                  )
                                ],
                              ).paddingOnly(left: 8),
                            ),
                          ),
                        ).onTap(() => changeCountry()),
                        10.width,
                        // Mobile number text field...
                        AppTextField(
                          textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                          controller: mobileCont,
                          focus: mobileFocus,
                          errorThisFieldRequired: 'This field is required',
                          nextFocus: passwordFocus,
                          decoration: inputDecoration(context, labelText: "Contact Number").copyWith(
                            hintText: 'Example: ${selectedCountry.example}',
                            hintStyle: secondaryTextStyle(),
                          ),
                          maxLength: 15,
                          suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                        ).expand(),
                      ],
                    ),
                    14.height,
                    AppTextField(
                      controller: TextEditingController(text: customer.email),
                      readOnly: true,
                      decoration: inputDecoration(
                        context,
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      textFieldType: TextFieldType.EMAIL,
                    ).paddingSymmetric(horizontal: AppConstants.horizontalPadding),

                    32.height,
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

  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      showPhoneCode: true,
      onSelect: (Country country) {
        selectedCountryCode = country;
        valueNotifier.value = !valueNotifier.value;
        setState(() {});
      },
    );
  }
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
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 68),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF002B30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: onEditPhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: profileImage != null
                        ? ClipOval(
                            child: Image.file(
                              profileImage!,
                              fit: BoxFit.cover,
                              width: 92,
                              height: 92,
                            ),
                          )
                        : Center(
                            child: Text(
                              customer.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                  ),
                  // Edit badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.edit,
                          size: 14, color: AppColors.teal),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              customer.displayName,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              customer.email,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wave clipper ─────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
        size.width * 0.5, size.height + 8,
        size.width, size.height - 36,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
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
            shape: const RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all( Radius.circular(10))),

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


