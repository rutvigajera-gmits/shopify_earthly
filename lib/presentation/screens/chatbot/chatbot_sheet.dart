import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chatbot_message.dart';
import '../../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../providers/customer_provider.dart';
import 'widgets/bot_bubble.dart';
import 'widgets/chatbot_input_bar.dart';
import 'widgets/product_card_msg.dart';
import 'widgets/suggestion_chips_bar.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/user_bubble.dart';

void showChatbotSheet(BuildContext context) {
  context.read<ChatbotProvider>().init();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<ChatbotProvider>()),
        ChangeNotifierProvider.value(value: context.read<CartProvider>()),
        ChangeNotifierProvider.value(value: context.read<CustomerProvider>()),
      ],
      child: const _ChatbotSheet(),
    ),
  );
}

class _ChatbotSheet extends StatefulWidget {
  const _ChatbotSheet();

  @override
  State<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<_ChatbotSheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final chatbot = context.read<ChatbotProvider>();
    final cart = context.read<CartProvider>();
    final customer = context.read<CustomerProvider>();
    await chatbot.sendMessage(text,
        cartProvider: cart, customerProvider: customer);
    _scrollToBottom();
  }

  Future<void> _addToCart(Product product) async {
    final cartProvider = context.read<CartProvider>();
    final firstVariant = product.variants
        .where((v) => v.availableForSale)
        .firstOrNull;
    if (firstVariant == null) return;

    await cartProvider.addItem(firstVariant.id, 1);
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text('${product.title} added to bag'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Bag',
          textColor: AppColors.gold,
          onPressed: () {
            messenger.clearSnackBars();
            Navigator.of(context)
              ..pop()
              ..pushNamed(AppRoutes.cart);
          },
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.82, 0.95],
      builder: (_, __) => AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _DragHandle(),

              _ChatHeader(
                onClose: () => Navigator.of(context).pop(),
                onCartTap: () {
                  Navigator.of(context)
                    ..pop()
                    ..pushNamed(AppRoutes.cart);
                },
              ),

              const Divider(height: 1, color: AppColors.divider),

              Expanded(
                child: Consumer<ChatbotProvider>(
                  builder: (_, chatbot, __) {
                    final messages = chatbot.messages;
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount:
                          messages.length + (chatbot.isTyping ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (chatbot.isTyping && i == messages.length) {
                          return const TypingIndicator();
                        }
                        return _buildMessage(messages[i]);
                      },
                    );
                  },
                ),
              ),

              Consumer<ChatbotProvider>(
                builder: (_, chatbot, __) => ChatbotInputBar(
                  onSend: _send,
                  enabled: !chatbot.isTyping,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.isTyping) return const TypingIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.role == ChatRole.user)
          UserBubble(text: message.text)
        else
          BotBubble(text: message.text, isError: message.isError),

        if (message.role == ChatRole.bot &&
            message.products != null &&
            message.products!.isNotEmpty)
          ProductCarouselMsg(
            products: message.products!,
            onAddToCart: _addToCart,
          ),

        if (message.role == ChatRole.bot &&
            message.suggestions != null &&
            message.suggestions!.isNotEmpty)
          SuggestionChipsBar(
            suggestions: message.suggestions!,
            onTap: _send,
          ),

        const SizedBox(height: 4),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.neutral300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onCartTap;

  const _ChatHeader({required this.onClose, required this.onCartTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.chatAvatar,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Earthly Jewels Assistant',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Text(
                //   'Earthly Jewels Assistant',
                //   style: TextStyle(
                //     color: AppColors.textMuted,
                //     fontSize: 11,
                //   ),
                // ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCartTap,
            icon: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'View Cart',
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}
