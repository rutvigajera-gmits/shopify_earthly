class FormatUtils {
  FormatUtils._();

  // Formats a double amount as Indian rupee string, e.g. ₹1,23,456.
  static String formatPrice(double amount, {String symbol = '₹'}) {
    final str = amount.toStringAsFixed(0);
    final formatted = str.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$symbol$formatted';
  }

  // Parses a raw Shopify price string and formats it as "Rs. 1,23,456".
  static String formatRsPrice(String raw) {
    final amount = double.tryParse(raw) ?? 0;
    return 'Rs. ${_commaSep(amount.toStringAsFixed(0))}';
  }

  static String _commaSep(String digits) => digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // Strips the "Exception: " prefix added by Dart's Exception.toString().
  static String trimException(dynamic e) =>
      e.toString().replaceFirst('Exception: ', '');

  // Appends `format=jpg` to Shopify CDN image URLs so the CDN converts
  // WebP/AVIF variants to JPEG, preventing Android ImageDecoder failures.
  static String shopifyImageJpeg(String url) {
    if (url.isEmpty || !url.contains('cdn.shopify.com')) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}format=jpg';
  }

  // Formats a DateTime as "Month DD, YYYY".
  static String formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
