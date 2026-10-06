import '../../data/models/home_api_model.dart';
import '../../data/repositories/home_repository.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/format_utils.dart';
import '../common/base_provider.dart';

class HomeProvider extends BaseProvider {
  final _repo = HomeRepository.instance;

  HomeApiResponse? _data;
  bool _initialized = false;

  HomeApiResponse? get data => _data;
  bool get initialized => _initialized;

  HomeTheme? get theme => _data?.theme;
  HomeGlobal? get global => _data?.global;
  List<HomeSection> get sections => _data?.sections ?? [];

  String get logoUrl => _data?.theme.logo.url ?? '';
  String get shopName => _data?.global.shopName ?? AppStrings.defaultShopName;

  List<String> get announcements {
    final msgs = _data?.global.announcements ?? [];
    return msgs.isNotEmpty ? msgs : const [AppStrings.defaultAnnouncement];
  }

  Future<void> initialize() async {
    if (_initialized) return;
    setLoading();
    try {
      _data = await _repo.fetchHome();
      _initialized = true;
      setLoaded();
    } catch (e) {
      setError(FormatUtils.trimException(e));
      _initialized = true;
    }
  }

  Future<void> refresh() async {
    setLoading();
    try {
      _data = await _repo.fetchHome();
      _initialized = true;
      setLoaded();
    } catch (e) {
      setError(FormatUtils.trimException(e));
    }
  }
}
