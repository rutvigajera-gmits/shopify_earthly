import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  WishlistService._();
  static const _key = 'wishlist_handles';

  static Future<List<String>> getHandles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addHandle(String handle) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    if (!list.contains(handle)) {
      list.insert(0, handle);
      await prefs.setStringList(_key, list);
    }
  }

  static Future<void> removeHandle(String handle) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(handle);
    await prefs.setStringList(_key, list);
  }
}
