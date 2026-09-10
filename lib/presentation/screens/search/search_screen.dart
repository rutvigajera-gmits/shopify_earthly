import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../widgets/product_card.dart';

const _kMinQueryLength = 2;
const _kDebounceDuration = Duration(milliseconds: 500);

const List<String> _trending = [
  'Diamond Ring',
  'Solitaire',
  'Engagement Ring',
  'Earrings',
  'Lab Grown Diamond',
  'Necklace',
  'Eternity Band',
  'Tennis Bracelet',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final query = raw.trim();

    _debounce?.cancel();

    if (query.length < _kMinQueryLength) {
      if (_lastQuery.isNotEmpty) {
        _lastQuery = '';
        context.read<ProductProvider>().clearSearch();
      }
      setState(() {});
      return;
    }

    if (query == _lastQuery) {
      setState(() {});
      return;
    }

    // Mark as pending so UI doesn't show "No results" while waiting
    setState(() {});
    _debounce = Timer(_kDebounceDuration, () {
      _lastQuery = query;
      context.read<ProductProvider>().search(query);
    });
  }

  void _onClear() {
    _controller.clear();
    _lastQuery = '';
    _debounce?.cancel();
    context.read<ProductProvider>().clearSearch();
    setState(() {});
  }

  void _searchTerm(String term) {
    _controller.text = term;
    _lastQuery = term;
    _debounce?.cancel();
    context.read<ProductProvider>().search(term);
    setState(() {});
  }

  bool get _hasQuery => _controller.text.trim().length >= _kMinQueryLength;

  // True when user has typed enough but debounce hasn't fired yet
  bool get _isPending =>
      _hasQuery && _controller.text.trim() != _lastQuery;

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
          onChanged: _onChanged,
          onClear: _onClear,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // No query or debounce pending — show trending
          if (!_hasQuery || _isPending) {
            return _TrendingSearches(
              terms: _trending,
              onTap: _searchTerm,
            );
          }

          if (provider.loadingSearch) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPrimary,
              ),
            );
          }

          if (provider.searchResults.isEmpty) {
            return _EmptyResults(query: _controller.text.trim());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.horizontalPadding, 14, 0, 0),
                child: Text(
                  '${provider.searchResults.length} result${provider.searchResults.length == 1 ? '' : 's'}',
                  style: AppTextStyles.labelSmall,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.horizontalPadding),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Search field ────────────────────────────────────────────────────────────

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
      textInputAction: TextInputAction.search,
      onSubmitted: (v) => onChanged(v),
      decoration: InputDecoration(
        hintText: 'Search jewellery...',
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textLight, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (ctx, value, _) => value.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textSecondary),
                )
              : const SizedBox.shrink(),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

// ─── Trending searches ───────────────────────────────────────────────────────

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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.north_west,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      term,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Empty results ───────────────────────────────────────────────────────────

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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
