import '../../data/models/cart_model.dart';
import '../common/base_provider.dart';

class OrderProvider extends BaseProvider {
  String? _transactionId;
  List<CartLineItem> _items = const [];
  double _total = 0;
  String _customerName = '';
  String _deliveryAddress = '';

  String? get transactionId => _transactionId;
  List<CartLineItem> get items => _items;
  double get total => _total;
  String get customerName => _customerName;
  String get deliveryAddress => _deliveryAddress;
  bool get hasOrder => _transactionId != null;

  void setOrder({
    required String transactionId,
    required List<CartLineItem> items,
    required double total,
    required String customerName,
    required String deliveryAddress,
  }) {
    _transactionId = transactionId;
    _items = List.unmodifiable(items);
    _total = total;
    _customerName = customerName;
    _deliveryAddress = deliveryAddress;
    notifyListeners();
  }

  void clear() {
    _transactionId = null;
    _items = const [];
    _total = 0;
    _customerName = '';
    _deliveryAddress = '';
    notifyListeners();
  }
}
