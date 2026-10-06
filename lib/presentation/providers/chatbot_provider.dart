import 'package:flutter/material.dart';
import '../../data/models/chatbot_message.dart';
import '../../data/models/product_model.dart';
import '../../data/services/chatbot_service.dart';
import '../../data/services/shopify_service.dart';
import 'cart_provider.dart';
import 'customer_provider.dart';

enum _ChatIntent { productSearch, orderInquiry, cartAction, faq, general }

class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider._();
  static final ChatbotProvider instance = ChatbotProvider._();

  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get hasMessages => _messages.isNotEmpty;

  void init() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.welcome());
      notifyListeners();
    }
  }

  void clearSession() {
    _messages.clear();
    _history.clear();
    _isTyping = false;
    _messages.add(ChatMessage.welcome());
    notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    required CartProvider cartProvider,
    required CustomerProvider customerProvider,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      text: trimmed,
    ));
    _history.add({'role': 'user', 'content': trimmed});

    // Show typing indicator
    _isTyping = true;
    notifyListeners();

    try {
      final intent = _detectIntent(trimmed);
      List<Product>? contextProducts;

      // Fetch Shopify products if relevant
      if (intent == _ChatIntent.productSearch) {
        final query = _extractSearchQuery(trimmed);
        try {
          contextProducts =
              await ShopifyService.instance.searchProducts(query);
        } catch (_) {
          contextProducts = null;
        }
      }

      final serviceResponse = await ChatbotService.instance.getResponse(
        userMessage: trimmed,
        conversationHistory: _history,
        contextProducts: contextProducts,
        customerOrders: customerProvider.isLoggedIn
            ? customerProvider.orders
            : null,
        isLoggedIn: customerProvider.isLoggedIn,
      );

      // Resolve product handles → full Product objects
      List<Product>? resolvedProducts;
      if (serviceResponse.productHandles.isNotEmpty) {
        resolvedProducts = contextProducts
                ?.where((p) =>
                    serviceResponse.productHandles.contains(p.handle))
                .toList() ??
            [];
        if (resolvedProducts.isEmpty) resolvedProducts = null;
      }

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.bot,
        text: serviceResponse.text,
        products: resolvedProducts,
        suggestions: serviceResponse.suggestions.isNotEmpty
            ? serviceResponse.suggestions
            : null,
      );

      _messages.add(botMessage);
      _history.add({'role': 'assistant', 'content': serviceResponse.text});

      // Keep history manageable (last 12 entries = 6 exchanges)
      if (_history.length > 12) {
        _history.removeRange(0, _history.length - 12);
      }
    } catch (e) {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.bot,
        text: 'Something went wrong. Please try again.',
        isError: true,
        suggestions: const ['Try again', 'Show me rings'],
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // ── Intent Detection ──────────────────────────────────────────────────────

  _ChatIntent _detectIntent(String message) {
    final lower = message.toLowerCase();

    if (RegExp(
            r'add to cart|add to bag|add it|buy now|purchase|order this')
        .hasMatch(lower)) {
      return _ChatIntent.cartAction;
    }

    if (RegExp(r'\border\b|track|delivery|shipped|dispatch|where is my|order status|order number')
        .hasMatch(lower)) {
      return _ChatIntent.orderInquiry;
    }

    if (RegExp(r'return|refund|polic|shipping|ship|deliver|care|warranty|certif|igi|about|store|contact|locat|hour')
        .hasMatch(lower)) {
      return _ChatIntent.faq;
    }

    if (RegExp(
            r'ring|necklace|bracelet|earring|pendant|diamond|gold|silver|'
            r'solitaire|halo|show|find|search|collection|suggest|recommend|'
            r'best.?seller|new|under|below|price|budget|gift|buy|shop|browse|'
            r'jewel|product|pear|oval|round|princess|cushion|emerald|marquise|'
            r'rectangle|square|heart|trillion|shape|cut|lab.?grown|igi|carat|'
            r'affordable|cheap|expensive|luxury|wedding|engagement|anniversary|'
            r'daily|wear|casual|party|festive|gift|pearl|gemstone')
        .hasMatch(lower)) {
      return _ChatIntent.productSearch;
    }

    return _ChatIntent.general;
  }

  String _extractSearchQuery(String message) {
    return message
        .toLowerCase()
        .replaceAll(
            RegExp(
                r'show me|show|find me|find|i want|looking for|do you have|'
                r'can you show|what about|search for|search|get me|'
                r'display|list|recommend|suggest'),
            '')
        .trim();
  }
}
