import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../services/shopify_service.dart';

class CustomerProvider extends ChangeNotifier {
  final _service = ShopifyService.instance;

  Customer? _customer;
  String? _accessToken;
  List<CustomerOrder> _orders = [];
  List<CustomerAddress> _addresses = [];

  bool _loading = false;
  bool _ordersLoading = false;
  bool _ordersLoaded = false;
  bool _addressesLoading = false;
  String? _error;

  bool get isLoggedIn => _customer != null && _accessToken != null;
  Customer? get customer => _customer;
  List<CustomerOrder> get orders => _orders;
  List<CustomerAddress> get addresses => _addresses;
  bool get loading => _loading;
  bool get ordersLoading => _ordersLoading;
  bool get addressesLoading => _addressesLoading;
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

  // ─── Profile update ───────────────────────────────────────────────────────

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    if (_accessToken == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateCustomer(
        accessToken: _accessToken!,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      if (updated != null) _customer = updated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Address management ───────────────────────────────────────────────────

  Future<void> loadAddresses() async {
    if (_accessToken == null || _addressesLoading) return;
    _addressesLoading = true;
    notifyListeners();
    try {
      _addresses = await _service.fetchCustomerAddresses(_accessToken!);
    } catch (_) {
      _addresses = [];
    } finally {
      _addressesLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addAddress(Map<String, String> address) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      final created = await _service.createCustomerAddress(
        accessToken: _accessToken!,
        address: address,
      );
      _addresses.insert(0, created);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> editAddress(
      String addressId, Map<String, String> address) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      final updated = await _service.updateCustomerAddress(
        accessToken: _accessToken!,
        addressId: addressId,
        address: address,
      );
      final idx = _addresses.indexWhere((a) => a.id == addressId);
      if (idx != -1) {
        _addresses[idx] = updated.copyWith(isDefault: _addresses[idx].isDefault);
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> removeAddress(String addressId) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      await _service.deleteCustomerAddress(
        accessToken: _accessToken!,
        addressId: addressId,
      );
      _addresses.removeWhere((a) => a.id == addressId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> makeDefaultAddress(String addressId) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      await _service.setDefaultCustomerAddress(
        accessToken: _accessToken!,
        addressId: addressId,
      );
      _addresses = _addresses
          .map((a) => a.copyWith(isDefault: a.id == addressId))
          .toList();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
