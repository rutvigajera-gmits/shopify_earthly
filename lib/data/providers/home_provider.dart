import 'package:flutter/foundation.dart';
import '../models/home_api_model.dart';
import '../services/storefront_home_service.dart';

class HomeProvider extends ChangeNotifier {
  final _service = StorefrontHomeService.instance;

  HomeApiResponse? _data;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  HomeApiResponse? get data => _data;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;

  HomeTheme? get theme => _data?.theme;
  HomeGlobal? get global => _data?.global;
  List<HomeSection> get sections => _data?.sections ?? [];

  String get logoUrl => _data?.theme.logo.url ?? '';
  String get shopName => _data?.global.shopName ?? 'Earthly Jewels';

  List<String> get announcements {
    final msgs = _data?.global.announcements ?? [];
    return msgs.isNotEmpty
        ? msgs
        : const ['BOOK YOUR STORE VISIT - ANDHERI WEST MUMBAI'];
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();
    try {
      _data = await _service.fetchHome();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _service.fetchHome();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    _initialized = true;
    notifyListeners();
  }
}
