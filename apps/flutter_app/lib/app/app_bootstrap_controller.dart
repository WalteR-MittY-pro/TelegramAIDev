import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../shared/assets/shared_asset_repository.dart';
import '../shared/assets/shared_models.dart';

enum BootstrapPhase { loading, noSession, failure }

enum DemoLoginPhase { idle, submitting, authenticated }

class AppBootstrapController extends ChangeNotifier {
  AppBootstrapController({required SharedAssetRepository repository})
    : _repository = repository {
    load();
  }

  final SharedAssetRepository _repository;

  BootstrapPhase _phase = BootstrapPhase.loading;
  DemoLoginPhase _demoLoginPhase = DemoLoginPhase.idle;
  BootstrapCopy _bootstrapCopy = BootstrapCopy.fallback();
  SharedStartupConfig? _startupConfig;
  String? _failureMessage;
  String? _loginErrorMessage;

  BootstrapPhase get phase => _phase;
  DemoLoginPhase get demoLoginPhase => _demoLoginPhase;
  BootstrapCopy get bootstrapCopy => _bootstrapCopy;
  SharedStartupConfig? get startupConfig => _startupConfig;
  String? get failureMessage => _failureMessage;
  String? get loginErrorMessage => _loginErrorMessage;
  bool get isAuthenticated => _demoLoginPhase == DemoLoginPhase.authenticated;
  bool get isSubmittingLogin => _demoLoginPhase == DemoLoginPhase.submitting;

  Future<void> load() async {
    _phase = BootstrapPhase.loading;
    _failureMessage = null;
    _loginErrorMessage = null;
    _demoLoginPhase = DemoLoginPhase.idle;
    notifyListeners();

    try {
      final BootstrapCopy? loadedBootstrapCopy = await _repository
          .tryLoadBootstrapCopy();
      if (loadedBootstrapCopy != null) {
        _bootstrapCopy = loadedBootstrapCopy;
        notifyListeners();
      }

      final SharedStartupConfig startupConfig = await _repository
          .loadStartupConfig();
      _bootstrapCopy = startupConfig.bootstrapCopy;
      _startupConfig = startupConfig;
      _phase = BootstrapPhase.noSession;
      notifyListeners();
    } catch (error, stackTrace) {
      log(
        'Failed to load startup configuration.',
        name: 'flutter.telegram.bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
      _failureMessage = _bootstrapCopy.failureNotice;
      _phase = BootstrapPhase.failure;
      notifyListeners();
    }
  }

  Future<void> submitDemoLogin(String rawPhoneNumber) async {
    if (_phase != BootstrapPhase.noSession || isSubmittingLogin) {
      return;
    }

    final String normalizedPhoneNumber = _normalizePhoneNumber(rawPhoneNumber);
    final LoginCopy copy = _startupConfig?.loginCopy ?? LoginCopy.fallback();
    if (!_isValidPhoneNumber(normalizedPhoneNumber)) {
      _loginErrorMessage = copy.invalidInputNotice;
      notifyListeners();
      return;
    }

    _loginErrorMessage = null;
    _demoLoginPhase = DemoLoginPhase.submitting;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));
    _demoLoginPhase = DemoLoginPhase.authenticated;
    notifyListeners();
  }

  void clearLoginError() {
    if (_loginErrorMessage == null) {
      return;
    }
    _loginErrorMessage = null;
    notifyListeners();
  }

  bool _isValidPhoneNumber(String normalizedPhoneNumber) {
    final int digitCount = normalizedPhoneNumber.replaceAll('+', '').length;
    return normalizedPhoneNumber.startsWith('+') &&
        digitCount >= 7 &&
        digitCount <= 15;
  }

  String _normalizePhoneNumber(String rawPhoneNumber) {
    final String digitsOnly = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return '';
    }
    return '+$digitsOnly';
  }
}
