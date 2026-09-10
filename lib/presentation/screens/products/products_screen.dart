import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/product_card.dart';

// Category tab definition
class _Category {
  final String label;
  final String handle; // empty = All (best sellers)
  const _Category(this.label, this.handle);
}

const List<_Category> _categories = [
  _Category('All', ''),
  _Category('Rings', 'lab-grown-diamond-rings'),
  _Category('Earrings', 'lab-grown-diamond-earrings'),
  _Category('Necklace', 'lab-grown-diamond-necklace'),
  _Category('Bracelets', 'lab-grown-diamond-bracelets'),
  _Category('Men\'s', 'mens-ring'),
];

const List<String> _sortOptions = [
  'Featured',
  'Price: Low to High',
  'Price: High to Low',
  'Newest',
];

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;

  const ProductsScreen({super.key, this.onSearchTap, this.onCartTap});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _selectedCategory = 0;
  String _sortBy = 'Featured';
  double _minPrice = 0;
  double _maxPrice = 500000;
  bool _filtersActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadFeaturedProducts();
    });
  }

  void _onCategoryChanged(int index) {
    if (_selectedCategory == index) return;
    setState(() => _selectedCategory = index);
    final handle = _categories[index].handle;
    if (handle.isEmpty) {
      context.read<ProductProvider>().loadFeaturedProducts();
    } else {
      context.read<ProductProvider>().loadCollectionProducts(handle);
    }
  }

  void _openFilterSheet() {
    double tempMin = _minPrice;
    double tempMax = _maxPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter', style: AppTextStyles.headlineSmall),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Price Range', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${tempMin.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        tempMax >= 500000
                            ? '₹5,00,000+'
                            : '₹${tempMax.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(tempMin, tempMax),
                    min: 0,
                    max: 500000,
                    divisions: 100,
                    activeColor: AppColors.textPrimary,
                    inactiveColor: AppColors.border,
                    onChanged: (v) => setSheetState(() {
                      tempMin = v.start;
                      tempMax = v.end;
                    }),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _minPrice = 0;
                              _maxPrice = 500000;
                              _filtersActive = false;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text('Clear', style: AppTextStyles.button
                                .copyWith(color: AppColors.textPrimary, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _minPrice = tempMin;
                              _maxPrice = tempMax;
                              _filtersActive =
                                  tempMin > 0 || tempMax < 500000;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: AppColors.textPrimary,
                            alignment: Alignment.center,
                            child: Text('Apply', style: AppTextStyles.button
                                .copyWith(color: AppColors.textWhite, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            onSelected: _onCategoryChanged,
          ),
          const Divider(height: 1),
          _SortFilterBar(
            sortBy: _sortBy,
            filtersActive: _filtersActive,
            onSortChanged: (v) => setState(() => _sortBy = v),
            onFilterTap: _openFilterSheet,
          ),
          const Divider(height: 1),
          Expanded(
            child: _ProductGrid(
              categoryHandle: _categories[_selectedCategory].handle,
              sortBy: _sortBy,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category tab bar ────────────────────────────────────────────────────────

class _CategoryTabBar extends StatelessWidget {
  final List<_Category> categories;
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
                categories[i].label,
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

// ─── Sort & filter bar ───────────────────────────────────────────────────────

class _SortFilterBar extends StatelessWidget {
  final String sortBy;
  final bool filtersActive;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onFilterTap;

  const _SortFilterBar({
    required this.sortBy,
    required this.filtersActive,
    required this.onSortChanged,
    required this.onFilterTap,
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
          GestureDetector(
            onTap: onFilterTap,
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: filtersActive
                      ? AppColors.gold
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  filtersActive ? 'Filter •' : 'Filter',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 13,
                    color: filtersActive
                        ? AppColors.gold
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
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
              items: _sortOptions
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

// ─── Product grid ─────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final String categoryHandle;
  final String sortBy;
  final double minPrice;
  final double maxPrice;

  const _ProductGrid({
    required this.categoryHandle,
    required this.sortBy,
    required this.minPrice,
    required this.maxPrice,
  });

  List<Product> _applySort(List<Product> products) {
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
      case 'Newest':
        // Products are already ordered by collection/best-selling;
        // reverse to approximate newest-first.
        list.sort((a, b) => b.id.compareTo(a.id));
      default:
        break;
    }
    return list;
  }

  List<Product> _applyPriceFilter(List<Product> products) {
    if (minPrice <= 0 && maxPrice >= 500000) return products;
    return products.where((p) {
      final price = double.tryParse(p.minPrice) ?? 0;
      return price >= minPrice && (maxPrice >= 500000 || price <= maxPrice);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final isAll = categoryHandle.isEmpty;
        final loading = isAll
            ? provider.loadingFeatured
            : provider.loadingCollection;

        if (loading) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppConstants.horizontalPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 24,
              childAspectRatio: 0.65,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const ProductCardSkeleton(),
          );
        }

        final raw = isAll
            ? provider.featuredProducts
            : (provider.loadedCollectionHandle == categoryHandle
                ? provider.collectionProducts
                : const <Product>[]);

        final products = _applyPriceFilter(_applySort(raw));

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond_outlined,
                    size: 48, color: AppColors.textLight),
                const SizedBox(height: 12),
                Text(
                  'No products found',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
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
