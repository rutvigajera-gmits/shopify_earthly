import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/utils/format_utils.dart';
import '../models/chatbot_message.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';

class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''
You are Ring Matchmaker, a warm and knowledgeable jewelry assistant for Earthly Jewels.

ABOUT EARTHLY JEWELS:
- Premium lab-grown diamond jewelry brand (earthlyjewels.co)
- Products: rings, earrings, necklaces, bracelets, pendants
- All diamonds are IGI-certified lab-grown diamonds
- Metals: Yellow Gold, White Gold, Rose Gold
- Currency: Indian Rupees (INR, symbol ₹)
- Price range: ₹3,500 to ₹1,00,000+
- All diamonds are ethically grown in a lab — same physical/chemical properties as mined diamonds

POLICIES:
- Free shipping on orders above ₹5,000
- Standard delivery: 5–7 business days
- Returns: 7 days for unworn items in original packaging with IGI certificate
- Each piece comes with IGI certification

RESPONSE RULES:
1. Be warm, concise, and helpful — max 2–3 sentences
2. Recommend products from the AVAILABLE PRODUCTS list when relevant
3. Never invent product details, prices, or availability
4. For questions you cannot answer: say "I'll connect you with our support team."
5. Always respond ONLY with valid JSON — no extra text, no markdown code blocks:

{"text":"your response here","product_handles":["handle1"],"suggestions":["Quick reply 1","Quick reply 2"]}

Keep suggestions short (max 5 words each). product_handles must only contain handles from AVAILABLE PRODUCTS.
''';

  Future<ChatbotServiceResponse> getResponse({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    List<Product>? contextProducts,
    List<CustomerOrder>? customerOrders,
    bool isLoggedIn = false,
  }) async {
    final userContent = _buildUserContent(
      userMessage: userMessage,
      contextProducts: contextProducts,
      customerOrders: customerOrders,
      isLoggedIn: isLoggedIn,
    );

    // Build messages array for chat completion
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      // Include last 6 exchanges from history
      ...conversationHistory.takeLast(6),
      {'role': 'user', 'content': userContent},
    ];

    const maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
              },
              body: jsonEncode({
                'model': ApiConfig.groqModel,
                'messages': messages,
                'temperature': 0.7,
                'max_tokens': 512,
                'response_format': {'type': 'json_object'},
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final rawText = (data['choices'] as List?)
                  ?.firstOrNull?['message']?['content'] as String? ??
              '';
          return _parseResponse(rawText);
        }

        final isRetryable =
            response.statusCode == 429 || response.statusCode == 503;
        if (isRetryable && attempt < maxAttempts - 1) continue;

        String errorDetail = 'Status ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          errorDetail = err['error']?['message'] as String? ?? errorDetail;
        } catch (_) {}
        return ChatbotServiceResponse(
          text: 'Sorry, I\'m having trouble right now. Please try again in a moment.',
          productHandles: const [],
          suggestions: const ['Try again', 'Show me rings', 'Contact support'],
        );
      } catch (e) {
        if (attempt < maxAttempts - 1) continue;
        return ChatbotServiceResponse(
          text: 'Connection error. Please check your internet and try again.',
          productHandles: const [],
          suggestions: const ['Try again'],
        );
      }
    }
    return ChatbotServiceResponse.fallback();
  }

  String _buildUserContent({
    required String userMessage,
    List<Product>? contextProducts,
    List<CustomerOrder>? customerOrders,
    bool isLoggedIn = false,
  }) {
    final buffer = StringBuffer();

    if (contextProducts != null && contextProducts.isNotEmpty) {
      buffer.writeln('AVAILABLE PRODUCTS (from live Shopify store):');
      for (final p in contextProducts.take(8)) {
        final price = FormatUtils.formatPrice(
          double.tryParse(p.minPrice) ?? 0,
        );
        final available = p.availableForSale ? 'In stock' : 'Out of stock';
        final metals = p.options
            .where((o) => o.name.toLowerCase().contains('metal'))
            .expand((o) => o.values)
            .join(', ');
        buffer.writeln(
          '- ${p.title} | handle: ${p.handle} | Price from: $price | $available'
          '${metals.isNotEmpty ? ' | Metals: $metals' : ''}',
        );
      }
    } else {
      buffer.writeln(
          'AVAILABLE PRODUCTS: Not loaded. Do not reference specific products.');
    }

    if (isLoggedIn && customerOrders != null && customerOrders.isNotEmpty) {
      buffer.writeln('\nCUSTOMER ORDER HISTORY (last 3 orders):');
      for (final o in customerOrders.take(3)) {
        buffer.writeln(
          '- Order ${o.name} | Status: ${o.fulfillmentStatus} '
          '| ${o.lineItems.length} item(s) | Total: ${o.totalPrice}',
        );
      }
    } else if (!isLoggedIn) {
      buffer.writeln(
          '\nCUSTOMER: Not logged in. For order queries, ask them to sign in.');
    }

    buffer.writeln('\nCustomer message: $userMessage');
    return buffer.toString();
  }

  ChatbotServiceResponse _parseResponse(String raw) {
    try {
      // Strip markdown code fences if model wraps output
      final cleaned = raw
          .trim()
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final result = ChatbotServiceResponse.fromJson(json);
      if (result.text.isEmpty) return ChatbotServiceResponse.fallback();
      return result;
    } catch (_) {
      final text = raw.trim().isNotEmpty ? raw.trim() : null;
      return ChatbotServiceResponse(
        text: text ?? ChatbotServiceResponse.fallback().text,
        productHandles: const [],
        suggestions: const ['Show me rings', 'Contact support'],
      );
    }
  }
}

extension _ListExtension<T> on List<T> {
  List<T> takeLast(int n) =>
      length <= n ? this : sublist(length - n);
}
