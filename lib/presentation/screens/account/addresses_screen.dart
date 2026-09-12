import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/providers/customer_provider.dart';
import '../../widgets/app_header.dart';

// ─── Addresses List Screen ────────────────────────────────────────────────────

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadAddresses();
    });
  }

  Future<void> _openForm({CustomerAddress? address}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(existing: address),
      ),
    );
  }

  Future<void> _delete(CustomerAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete address?', style: AppTextStyles.headlineSmall),
        content: Text(
          address.lines.join(', '),
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final err = await context.read<CustomerProvider>().removeAddress(address.id);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _setDefault(CustomerAddress address) async {
    final err =
        await context.read<CustomerProvider>().makeDefaultAddress(address.id);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Saved Addresses', showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (_, provider, __) {
                if (provider.addressesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (provider.addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 56,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text('No saved addresses',
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a delivery address',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.horizontalPadding),
                  itemCount: provider.addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _AddressCard(
                    address: provider.addresses[i],
                    onEdit: () => _openForm(address: provider.addresses[i]),
                    onDelete: () => _delete(provider.addresses[i]),
                    onSetDefault: () => _setDefault(provider.addresses[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address Card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color:
              address.isDefault ? AppColors.gold : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.displayName,
                  style: AppTextStyles.labelLarge,
                ),
              ),
              if (address.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.goldLight,
                  child: Text(
                    'DEFAULT',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.gold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...address.lines.map(
            (line) => Text(line, style: AppTextStyles.bodySmall),
          ),
          if (address.phone?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              address.phone!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _ActionButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                onTap: onDelete,
                danger: true,
              ),
              if (!address.isDefault) ...[
                const SizedBox(width: 12),
                _ActionButton(
                  label: 'Set Default',
                  icon: Icons.check_circle_outline,
                  onTap: onSetDefault,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade600 : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address Form Screen ──────────────────────────────────────────────────────

class AddressFormScreen extends StatefulWidget {
  final CustomerAddress? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _country;
  late final TextEditingController _zip;
  late final TextEditingController _phone;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _firstName = TextEditingController(text: a?.firstName ?? '');
    _lastName = TextEditingController(text: a?.lastName ?? '');
    _address1 = TextEditingController(text: a?.address1 ?? '');
    _address2 = TextEditingController(text: a?.address2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _province = TextEditingController(text: a?.province ?? '');
    _country = TextEditingController(text: a?.country ?? 'India');
    _zip = TextEditingController(text: a?.zip ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _address1, _address2,
      _city, _province, _country, _zip, _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _addressMap => {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'address1': _address1.text.trim(),
        'address2': _address2.text.trim(),
        'city': _city.text.trim(),
        'province': _province.text.trim(),
        'country': _country.text.trim(),
        'zip': _zip.text.trim(),
        'phone': _phone.text.trim(),
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CustomerProvider>();
    final String? err;
    if (_isEditing) {
      err = await provider.editAddress(widget.existing!.id, _addressMap);
    } else {
      err = await provider.addAddress(_addressMap);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Address updated' : 'Address added'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: _isEditing ? 'Edit Address' : 'Add Address',
        showBack: true,
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.horizontalPadding),
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'First Name',
                          controller: _firstName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Last Name',
                          controller: _lastName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Address Line 1',
                    controller: _address1,
                    required: true,
                    hint: 'House / Flat / Block No.',
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Address Line 2',
                    controller: _address2,
                    hint: 'Apartment, Area, Street (optional)',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'City',
                          controller: _city,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'PIN Code',
                          controller: _zip,
                          required: true,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'State',
                          controller: _province,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Country',
                          controller: _country,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'Phone',
                    controller: _phone,
                    keyboard: TextInputType.phone,
                    hint: '+91 98765 43210',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.textWhite,
                        disabledBackgroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing ? 'UPDATE ADDRESS' : 'SAVE ADDRESS',
                              style: AppTextStyles.button
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable form field ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType keyboard;
  final String? hint;

  const _Field({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboard = TextInputType.text,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textSecondary, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySmall,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide:
                  BorderSide(color: AppColors.textPrimary, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        ),
      ],
    );
  }
}
