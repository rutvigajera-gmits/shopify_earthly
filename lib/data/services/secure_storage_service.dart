import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
  );

  Future<String?> read(String key) => _s.read(key: key);
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);
  Future<void> delete(String key) => _s.delete(key: key);
}
