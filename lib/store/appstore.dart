import 'package:demo_earthly/core/config/api_config.dart';
import 'package:demo_earthly/core/utils/common.dart';
import 'package:demo_earthly/locale/applocalizations.dart';
import 'package:demo_earthly/locale/base_language.dart';
import 'package:demo_earthly/main.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'appstore.g.dart';

AppStore appStore = AppStore();

class AppStore = _AppStore with _$AppStore;

abstract class _AppStore with Store {
  static const _keyDarkMode = 'ej_dark_mode';

  @observable
  bool isDarkMode = false;

  @observable
  bool isLoading = false;

  @observable
  String selectedLanguageCode = getStringAsync(SELECTED_LANGUAGE_CODE, defaultValue: DEFAULT_LANGUAGE);

  @observable
  LanguageDataModel selectedLanguage = languageList().first;

  @action
  void setSelectedLanguage(LanguageDataModel val) {
    selectedLanguage = val;
  }

  @action
  Future<void> setLanguage(String val, {BuildContext? context}) async {
    selectedLanguageCode = val;
    selectedLanguageDataModel = getSelectedLanguageModel();

    await setValue(SELECTED_LANGUAGE_CODE, selectedLanguageCode);
    languages = await AppLocalizations().load(Locale(selectedLanguageCode));

    if (context != null) languages = Languages.of(context);

    errorMessage = languages.pleaseTryAgain;
    errorSomethingWentWrong = languages.somethingWentWrong;
    errorThisFieldRequired = languages.hintRequired;
    errorInternetNotAvailable = languages.internetNotAvailable;
  }

  @action
  Future<void> setDarkMode(bool val) async {
    isDarkMode = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, val);
  }

  @action
  void setLoading(bool val) => isLoading = val;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
  }
}

// Convenience extension used by theme-aware widgets.
extension AppStoreTheme on AppStore {
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
