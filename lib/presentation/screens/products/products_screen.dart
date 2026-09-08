import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;

  const ProductsScreen({super.key, this.onSearchTap, this.onCartTap});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _selectedCategory = 0;

  static const List<Map<String, String>> _categories = [
    {'label': 'All', 'handle': ''},
    {'label': 'Rings', 'handle': 'rings'},
    {'label': 'Earrings', 'handle': 'earrings'},
    {'label': 'Necklace', 'handle': 'necklaces'},
    {'label': 'Fine Jewellery', 'handle': 'fine-jewellery'},
    {'label': 'New Arrivals', 'handle': 'new-arrivals'},
  ];

  String _sortBy = 'Featured';
  static const List<String> _sortOptions = [
    'Featured',
    'Price: Low to High',
    'Price: High to Low',
    'Newest',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadFeaturedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Shop',
        onSearchTap: widget.onSearchTap,
        onCartTap: widget.onCartTap,
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          _CategoryTabBar(
            categories: _categories,
            selectedIndex: _selectedCategory,
            onSelected: (i) => setState(() => _selectedCategory = i),
          ),
          const Divider(height: 1),
          _SortFilterBar(
            sortBy: _sortBy,
            sortOptions: _sortOptions,
            onSortChanged: (v) => setState(() => _sortBy = v),
          ),
          const Divider(height: 1),
          Expanded(child: _ProductGrid(sortBy: _sortBy)),
        ],
      ),
    );
  }
}

class _CategoryTabBar extends StatelessWidget {
  final List<Map<String, String>> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryTabBar({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final isSelected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                categories[i]['label']!,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortFilterBar extends StatelessWidget {
  final String sortBy;
  final List<String> sortOptions;
  final ValueChanged<String> onSortChanged;

  const _SortFilterBar({
    required this.sortBy,
    required this.sortOptions,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          const Text('Filter', style: TextStyle(fontSize: 13)),
          const Spacer(),
          const Icon(Icons.sort, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortBy,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              items: sortOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onSortChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final String sortBy;
  const _ProductGrid({required this.sortBy});

  List<Product> _sorted(List<Product> products) {
    final list = List<Product>.from(products);
    switch (sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) =>
            (double.tryParse(a.minPrice) ?? 0)
                .compareTo(double.tryParse(b.minPrice) ?? 0));
      case 'Price: High to Low':
        list.sort((a, b) =>
            (double.tryParse(b.minPrice) ?? 0)
                .compareTo(double.tryParse(a.minPrice) ?? 0));
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loadingFeatured) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppConstants.horizontalPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 24,
              childAspectRatio: 0.65,
            ),
            itemCount: 6,
            itemBuilder: (ctx, i) => const ProductCardSkeleton(),
          );
        }

        final products = _sorted(provider.featuredProducts);

        if (products.isEmpty) {
          return const Center(
            child: Text('No products found'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.horizontalPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 24,
            childAspectRatio: 0.65,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => ProductCard(
            product: products[i],
            onTap: () => Navigator.of(context).pushNamed(
              '/product',
              arguments: products[i].handle,
            ),
          ),
        );
      },
    );
  }
}
