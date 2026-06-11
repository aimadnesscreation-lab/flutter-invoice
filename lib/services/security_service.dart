import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:invoice_pro/core/constants/app_constants.dart';

class SecurityService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  SecurityService()
      : _secureStorage = const FlutterSecureStorage(),
        _localAuth = LocalAuthentication();

  // PIN Code
  Future<void> setPinCode(String pin) async {
    await _secureStorage.write(key: AppConstants.pinCodeKey, value: pin);
  }

  Future<bool> verifyPinCode(String pin) async {
    final storedPin = await _secureStorage.read(key: AppConstants.pinCodeKey);
    return storedPin == pin;
  }

  Future<bool> hasPinCode() async {
    final pin = await _secureStorage.read(key: AppConstants.pinCodeKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> removePinCode() async {
    await _secureStorage.delete(key: AppConstants.pinCodeKey);
  }

  // Biometric
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Invoice Pro',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: AppConstants.isBiometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: AppConstants.isBiometricEnabledKey, value: enabled.toString());
  }

  // Auto Lock
  Future<void> setAutoLockDuration(int minutes) async {
    await _secureStorage.write(key: AppConstants.autoLockDurationKey, value: minutes.toString());
  }

  Future<int> getAutoLockDuration() async {
    final value = await _secureStorage.read(key: AppConstants.autoLockDurationKey);
    if (value == null) return 5; // Default 5 minutes
    return int.tryParse(value) ?? 5;
  }

  // Theme
  Future<void> setThemeMode(String mode) async {
    await _secureStorage.write(key: AppConstants.themeModeKey, value: mode);
  }

  Future<String> getThemeMode() async {
    return await _secureStorage.read(key: AppConstants.themeModeKey) ?? 'system';
  }
}
