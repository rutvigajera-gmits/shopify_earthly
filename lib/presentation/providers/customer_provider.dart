import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/services/local_order_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/format_utils.dart';
import '../common/base_provider.dart';

class CustomerProvider extends BaseProvider {
  final _repo = CustomerRepository.instance;

  Customer? _customer;
  String? _accessToken;
  String? _profileImagePath;
  List<CustomerOrder> _orders = [];
  List<CustomerAddress> _addresses = [];

  bool _ordersLoading = false;
  bool _ordersLoaded = false;
  bool _addressesLoading = false;

  bool get isLoggedIn => _customer != null && _accessToken != null;
  Customer? get customer => _customer;
  String? get accessToken => _accessToken;
  String? get profileImagePath => _profileImagePath;
  List<CustomerOrder> get orders => _orders;
  List<CustomerAddress> get addresses => _addresses;
  bool get ordersLoading => _ordersLoading;
  bool get addressesLoading => _addressesLoading;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppStrings.customerTokenKey);
      final imagePath = prefs.getString(AppStrings.profileImageKey);
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImagePath = imagePath;
      }
      if (token == null || token.isEmpty) {
        notifyListeners();
        return;
      }
      final customer = await _repo.fetchProfile(token);
      if (customer != null) {
        _customer = customer;
        _accessToken = token;
      } else {
        await prefs.remove(AppStrings.customerTokenKey);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setProfileImagePath(String? path) async {
    _profileImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(AppStrings.profileImageKey, path);
    } else {
      await prefs.remove(AppStrings.profileImageKey);
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    setLoading();
    try {
      final token = await _repo.login(email: email, password: password);
      _accessToken = token;
      _customer = await _repo.fetchProfile(token);
      _ordersLoaded = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppStrings.customerTokenKey, token);
      setLoaded();
    } catch (e) {
      setError(FormatUtils.trimException(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    setLoading();
    try {
      await _repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      final token = await _repo.login(email: email, password: password);
      _accessToken = token;
      _customer = await _repo.fetchProfile(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppStrings.customerTokenKey, token);
      setLoaded();
    } catch (e) {
      setError(FormatUtils.trimException(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordReset(email);
    } catch (_) {}
  }

  Future<void> logout() async {
    if (_accessToken != null) await _repo.logout(_accessToken!);
    _customer = null;
    _accessToken = null;
    _orders = [];
    _ordersLoaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStrings.customerTokenKey);
    notifyListeners();
  }

  Future<void> loadOrders({bool forceRefresh = false}) async {
    if (_ordersLoading || (_ordersLoaded && !forceRefresh)) return;
    _ordersLoading = true;
    notifyListeners();
    try {
      // Fetch from Shopify (requires login) and local storage in parallel.
      final results = await Future.wait([
        _accessToken != null
            ? _repo.fetchOrders(_accessToken!).catchError((_) => <CustomerOrder>[])
            : Future.value(<CustomerOrder>[]),
        LocalOrderService.instance.loadOrders(),
      ]);

      final shopifyOrders = results[0];
      final localOrders = results[1];

      // Merge: show Shopify orders first, then any local orders not already
      // present in Shopify (identified by their 'local_' prefixed id).
      final shopifyIds = shopifyOrders.map((o) => o.id).toSet();
      final localOnly =
          localOrders.where((o) => !shopifyIds.contains(o.id)).toList();

      _orders = [...shopifyOrders, ...localOnly];
      _ordersLoaded = true;
    } catch (_) {
      _orders = [];
    } finally {
      _ordersLoading = false;
      notifyListeners();
    }
  }

  /// Call after placing a new order so the next [loadOrders] re-fetches.
  void invalidateOrders() {
    _ordersLoaded = false;
  }

  Future<void> updateProfile({String? firstName, String? lastName, String? phone}) async {
    if (_accessToken == null) return;
    setLoading();
    try {
      final updated = await _repo.updateProfile(
        token: _accessToken!,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      if (updated != null) _customer = updated;
      setLoaded();
    } catch (e) {
      setError(FormatUtils.trimException(e));
    }
  }

  Future<void> loadAddresses() async {
    if (_accessToken == null || _addressesLoading) return;
    _addressesLoading = true;
    notifyListeners();
    try {
      _addresses = await _repo.fetchAddresses(_accessToken!);
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
      final created = await _repo.createAddress(token: _accessToken!, address: address);
      _addresses.insert(0, created);
      notifyListeners();
      return null;
    } catch (e) {
      return FormatUtils.trimException(e);
    }
  }

  Future<String?> editAddress(String addressId, Map<String, String> address) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      final updated = await _repo.updateAddress(
        token: _accessToken!,
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
      return FormatUtils.trimException(e);
    }
  }

  Future<String?> removeAddress(String addressId) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      await _repo.deleteAddress(token: _accessToken!, addressId: addressId);
      _addresses.removeWhere((a) => a.id == addressId);
      notifyListeners();
      return null;
    } catch (e) {
      return FormatUtils.trimException(e);
    }
  }

  Future<String?> makeDefaultAddress(String addressId) async {
    if (_accessToken == null) return 'Not logged in';
    try {
      await _repo.setDefaultAddress(token: _accessToken!, addressId: addressId);
      _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == addressId)).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return FormatUtils.trimException(e);
    }
  }
}
