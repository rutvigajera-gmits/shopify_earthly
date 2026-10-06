import 'package:flutter/foundation.dart';

enum ViewState { idle, loading, loaded, error }

/// Base class for all ChangeNotifier providers.
/// Provides a unified [state]/[error] contract so every screen can react
/// to the same loading/error/loaded lifecycle without duplicating fields.
abstract class BaseProvider extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isLoaded => _state == ViewState.loaded;

  @protected
  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  @protected
  void setLoaded() {
    _state = ViewState.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  @protected
  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    if (_state == ViewState.error) {
      _state = ViewState.idle;
    }
    _errorMessage = null;
    notifyListeners();
  }
}
