import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  RecentlyViewedService._();
  static const _key = 'recently_viewed';
  static const _max = 10;

  static Future<List<String>> getHandles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addHandle(String handle) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(handle);
    list.insert(0, handle);
    if (list.length > _max) list.removeLast();
    await prefs.setStringList(_key, list);
  }
}
