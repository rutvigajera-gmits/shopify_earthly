import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../services/shopify_service.dart';

class CustomerProvider extends ChangeNotifier {
  final _service = ShopifyService.instance;

  Customer? _customer;
  String? _accessToken;
  List<CustomerOrder> _orders = [];

  bool _loading = false;
  bool _ordersLoading = false;
  bool _ordersLoaded = false;
  String? _error;

  bool get isLoggedIn => _customer != null && _accessToken != null;
  Customer? get customer => _customer;
  List<CustomerOrder> get orders => _orders;
  bool get loading => _loading;
  bool get ordersLoading => _ordersLoading;
  String? get error => _error;

  // Called on app start — restores session from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('customer_token');
      if (token == null || token.isEmpty) return;
      final customer = await _service.fetchCustomer(token);
      if (customer != null) {
        _customer = customer;
        _accessToken = token;
      } else {
        await prefs.remove('customer_token');
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final token =
          await _service.loginCustomer(email: email, password: password);
      _accessToken = token;
      _customer = await _service.fetchCustomer(token);
      _ordersLoaded = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_token', token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createCustomer(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      // Auto-login after successful registration.
      final token =
          await _service.loginCustomer(email: email, password: password);
      _accessToken = token;
      _customer = await _service.fetchCustomer(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_token', token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
    } catch (_) {}
  }

  Future<void> logout() async {
    if (_accessToken != null) {
      await _service.logoutCustomer(_accessToken!);
    }
    _customer = null;
    _accessToken = null;
    _orders = [];
    _ordersLoaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customer_token');
    notifyListeners();
  }

  Future<void> loadOrders() async {
    if (_accessToken == null || _ordersLoaded) return;
    _ordersLoading = true;
    notifyListeners();
    try {
      _orders = await _service.fetchCustomerOrders(_accessToken!);
      _ordersLoaded = true;
    } catch (_) {
      _orders = [];
    } finally {
      _ordersLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
