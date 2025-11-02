import 'package:get_storage/get_storage.dart';

class StorageService {
  static final _box = GetStorage();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';

  /// Initialize GetStorage before using
  static Future<void> init() async {
    await GetStorage.init();
  }

  /// Save login info
  static Future<void> saveLogin(String username) async {
    await _box.write(_keyIsLoggedIn, true);
    await _box.write(_keyUsername, username);
  }

  /// Clear saved login info
  static Future<void> clearLogin() async {
    await _box.erase();
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _box.read(_keyIsLoggedIn) ?? false;
  }

  /// Retrieve saved username
  static String getUsername() {
    return _box.read(_keyUsername) ?? '';
  }
}
