import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/providers/shop_provider.dart';
import '../../widgets/app_header.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

void _openUrl(BuildContext context, String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
      .catchError((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
    return false;
  });
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: context.watch<ShopProvider>().brand?.storeName ?? 'Account',
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (_, auth, __) => ListView(
                children: [
                  auth.isLoggedIn
                      ? _LoggedInHeader(auth: auth)
                      : _GuestHeader(),

                  const Divider(height: 1),

                  if (auth.isLoggedIn) ...[
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'My Orders',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OrdersScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_border,
                      label: 'Wishlist',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/wishlist'),
                    ),
                    _MenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Saved Addresses',
                      onTap: () => _openUrl(
                          context, 'https://earthlyjewels.co/account/addresses'),
                    ),
                    _MenuItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Earthly Elite Membership',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                  ],

                  _MenuItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Book Store Visit',
                    onTap: () => _openUrl(
                        context, 'https://earthlyjewels.co/pages/store-locator'),
                  ),
                  _MenuItem(
                    icon: Icons.headset_mic_outlined,
                    label: 'Virtual Consultation',
                    onTap: () => _openUrl(context,
                        'https://earthlyjewels.co/pages/virtual-consultation'),
                  ),
                  _MenuItem(
                    icon: Icons.straighten_outlined,
                    label: 'Ring Size Guide',
                    onTap: () => _openUrl(context,
                        'https://earthlyjewels.co/pages/ring-size-chart'),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    label: 'About Us',
                    onTap: () =>
                        _openUrl(context, 'https://earthlyjewels.co/pages/about'),
                  ),
                  _MenuItem(
                    icon: Icons.article_outlined,
                    label: 'Blog',
                    onTap: () =>
                        _openUrl(context, 'https://earthlyjewels.co/blogs'),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'FAQ',
                    onTap: () =>
                        _openUrl(context, 'https://earthlyjewels.co/pages/faq'),
                  ),
                  _MenuItem(
                    icon: Icons.phone_outlined,
                    label: 'Contact Us',
                    onTap: () => _openUrl(
                        context, 'https://earthlyjewels.co/pages/contact'),
                  ),
                  _MenuItem(
                    icon: Icons.policy_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _openUrl(context,
                        'https://earthlyjewels.co/policies/privacy-policy'),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () => _openUrl(context,
                        'https://earthlyjewels.co/policies/terms-of-service'),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  if (auth.isLoggedIn)
                    _MenuItem(
                      icon: Icons.logout,
                      label: 'Sign Out',
                      onTap: () async {
                        final customerProvider =
                            context.read<CustomerProvider>();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Sign out?',
                                style: AppTextStyles.headlineSmall),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel',
                                    style: AppTextStyles.bodyMedium),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Sign Out',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await customerProvider.logout();
                        }
                      },
                    )
                  else
                    _MenuItem(
                      icon: Icons.login,
                      label: 'Sign In / Create Account',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Store info — dynamic from ShopProvider metafields
                  Consumer<ShopProvider>(
                    builder: (_, shop, __) =>
                        _StoreInfo(shop: shop),
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

// ─── Profile Header ───────────────────────────────────────────────────────────

class _LoggedInHeader extends StatelessWidget {
  final CustomerProvider auth;
  const _LoggedInHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    final customer = auth.customer!;
    return Container(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 1.5),
      color: AppColors.surface,
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              customer.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.displayName,
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text(customer.email, style: AppTextStyles.bodySmall),
                if (customer.phone != null &&
                    customer.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(customer.phone!,
                      style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 1.5),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.goldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 32, color: AppColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome!', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Sign in to view orders, wishlist & exclusive deals',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    color: AppColors.textPrimary,
                    child: Text(
                      'SIGN IN',
                      style: AppTextStyles.button.copyWith(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ─── Store Info (dynamic from ShopProvider metafields) ────────────────────────

class _StoreInfo extends StatelessWidget {
  final ShopProvider shop;
  const _StoreInfo({required this.shop});

  @override
  Widget build(BuildContext context) {
    final address = shop.sectionTitle('store_address');
    final hours = shop.sectionTitle('store_hours');
    final phone = shop.sectionTitle('store_phone');
    final email = shop.sectionTitle('store_email');

    // Don't render the card if none of the fields are configured
    if (address.isEmpty && hours.isEmpty && phone.isEmpty && email.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visit Us', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          if (address.isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, text: address),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.access_time, text: hours),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.phone_outlined, text: phone),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.mail_outline, text: email),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
