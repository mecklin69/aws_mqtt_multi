import 'package:get_storage/get_storage.dart';

class StorageService {
  static final _box = GetStorage();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';
  static const String _keyVendorID = 'vendorID';
  static const String _keyCompanyName = 'companyName';
  static const String _keyDeviceCount = 'deviceCount';

  /// Initialize GetStorage before using
  static Future<void> init() async {
    await GetStorage.init();
  }

  /// Save login info
  static Future<void> saveLogin(String username) async {
    await _box.write(_keyIsLoggedIn, true);
    await _box.write(_keyUsername, username);
  }

  /// Save vendor ID
  static Future<void> saveVendor(String vendorID) async {
    await _box.write(_keyVendorID, vendorID);
  }

  /// Save company name
  static Future<void> saveCompany(String companyName) async {
    await _box.write(_keyCompanyName, companyName);
  }

  /// Save device count
  static Future<void> saveDeviceCount(int count) async {
    await _box.write(_keyDeviceCount, count);
  }

  /// Get vendor ID
  static String getVendor() {
    return _box.read(_keyVendorID) ?? '';
  }

  /// Get company name
  static String getCompany() {
    return _box.read(_keyCompanyName) ?? '';
  }

  /// Get device count
  static int getDeviceCount() {
    return _box.read(_keyDeviceCount) ?? 0;
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
