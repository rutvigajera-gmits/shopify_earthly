import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  static const List<String> _trending = [
    'Diamond Ring',
    'Solitaire',
    'Engagement Ring',
    'Gold Earrings',
    'Lab Grown Diamond',
    'Necklace',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ProductProvider>().search(query);
  }

  void _onClear() {
    _controller.clear();
    context.read<ProductProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: _SearchField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onSearch,
          onClear: _onClear,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.loadingSearch) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.text.isEmpty) {
            return _TrendingSearches(
              terms: _trending,
              onTap: (term) {
                _controller.text = term;
                _onSearch(term);
              },
            );
          }

          if (provider.searchResults.isEmpty) {
            return _EmptyResults(query: _controller.text);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppConstants.horizontalPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 24,
              childAspectRatio: 0.65,
            ),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, i) => ProductCard(
              product: provider.searchResults[i],
              onTap: () => Navigator.of(context).pushNamed(
                '/product',
                arguments: provider.searchResults[i].handle,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search rings, earrings, necklaces...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLight,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (ctx, value, child) => value.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                )
              : const SizedBox.shrink(),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _TrendingSearches extends StatelessWidget {
  final List<String> terms;
  final ValueChanged<String> onTap;

  const _TrendingSearches({required this.terms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      children: [
        Text('Trending Searches', style: AppTextStyles.labelLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: terms.map((term) {
            return GestureDetector(
              onTap: () => onTap(term),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(term, style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
