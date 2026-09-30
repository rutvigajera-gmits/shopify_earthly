class StripePayModel {
  final String clientSecret;
  final String id;
  final String status;
  final int amount;
  final String currency;

  const StripePayModel({
    required this.clientSecret,
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
  });

  factory StripePayModel.fromJson(Map<String, dynamic> json) {
    return StripePayModel(
      clientSecret: json['client_secret'] as String? ?? '',
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? '',
    );
  }
}
