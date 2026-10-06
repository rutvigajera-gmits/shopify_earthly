import '../models/product_model.dart';

enum ChatRole { user, bot }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final List<Product>? products;
  final List<String>? suggestions;
  final bool isError;
  final bool isTyping;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.products,
    this.suggestions,
    this.isError = false,
    this.isTyping = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static ChatMessage typing() => ChatMessage(
        id: '__typing__',
        role: ChatRole.bot,
        text: '',
        isTyping: true,
      );

  static ChatMessage welcome() => ChatMessage(
        id: 'welcome',
        role: ChatRole.bot,
        text:
            'Welcome to Earthly Jewels! 👋\nI\'m Ring Matchmaker, your personal jewelry guide. Ask me anything — products, prices, orders, or styling advice.',
        suggestions: [
          'Show me best sellers',
          'Rings under ₹20,000',
          'What\'s new?',
          'Track my order',
        ],
      );
}

class ChatbotServiceResponse {
  final String text;
  final List<String> productHandles;
  final List<String> suggestions;

  const ChatbotServiceResponse({
    required this.text,
    required this.productHandles,
    required this.suggestions,
  });

  factory ChatbotServiceResponse.fallback() => const ChatbotServiceResponse(
        text:
            'I\'m having a little trouble right now. Please try again in a moment.',
        productHandles: [],
        suggestions: ['Show me rings', 'Contact support'],
      );

  factory ChatbotServiceResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotServiceResponse(
      text: json['text'] as String? ?? '',
      productHandles: (json['product_handles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
