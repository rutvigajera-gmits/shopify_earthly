import '../models/customer_model.dart';
import '../services/shopify_service.dart';

class CustomerRepository {
  CustomerRepository._();
  static final CustomerRepository instance = CustomerRepository._();

  final _service = ShopifyService.instance;

  Future<String> login({required String email, required String password}) =>
      _service.loginCustomer(email: email, password: password);

  Future<void> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) =>
      _service.createCustomer(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

  Future<Customer?> fetchProfile(String token) =>
      _service.fetchCustomer(token);

  Future<void> logout(String token) => _service.logoutCustomer(token);

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  Future<List<CustomerOrder>> fetchOrders(String token) =>
      _service.fetchCustomerOrders(token);

  Future<Customer?> updateProfile({
    required String token,
    String? firstName,
    String? lastName,
    String? phone,
  }) =>
      _service.updateCustomer(
        accessToken: token,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

  Future<List<CustomerAddress>> fetchAddresses(String token) =>
      _service.fetchCustomerAddresses(token);

  Future<CustomerAddress> createAddress({
    required String token,
    required Map<String, String> address,
  }) =>
      _service.createCustomerAddress(accessToken: token, address: address);

  Future<CustomerAddress> updateAddress({
    required String token,
    required String addressId,
    required Map<String, String> address,
  }) =>
      _service.updateCustomerAddress(
        accessToken: token,
        addressId: addressId,
        address: address,
      );

  Future<void> deleteAddress({
    required String token,
    required String addressId,
  }) =>
      _service.deleteCustomerAddress(
        accessToken: token,
        addressId: addressId,
      );

  Future<void> setDefaultAddress({
    required String token,
    required String addressId,
  }) =>
      _service.setDefaultCustomerAddress(
        accessToken: token,
        addressId: addressId,
      );
}
