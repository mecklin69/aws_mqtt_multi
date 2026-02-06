import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/amplify_service.dart';
import 'dashboard_screen.dart';
import '../services/storage_service.dart';
import '../services/aws_iot_services.dart'; // ✅ Import your AWS IoT service

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryColor = Color(0xFF1F8EFE);
  static const Color backgroundColor = Color(0xFF0F112A);
  static const Color cardColor = Color(0xFF1A1D3A);
  static const Color accentColor = Color(0xFF96C2DF);
  static const Color textColor = Colors.white;

  bool _isLoading = false;

  // ✅ Helper to show snackbar
  void _showSnack(String title, String message, {bool success = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success
          ? Colors.greenAccent.withOpacity(0.8)
          : Colors.redAccent.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  // -------------------------------------------------------------
  // 🚀 Handle Login
  // -------------------------------------------------------------
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnack("Error", "Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    final user = await AmplifyService.login(username, password);

    if (user == null) {
      setState(() => _isLoading = false);
      _showSnack("Login Failed", "Invalid email or password");
      return;
    }

    // ✅ Extract DB values
    final vendorID = user['vendorID'];
    final companyName = user['companyName'];
    final deviceCount = user['deviceCount'];

    // ✅ Store locally
    await StorageService.saveLogin(username);
    await StorageService.saveVendor(vendorID);
    await StorageService.saveCompany(companyName);
    await StorageService.saveDeviceCount(deviceCount);

    // ✅ Dispose old IoT
    if (Get.isRegistered<AwsIotService>()) {
      Get.find<AwsIotService>().disposeService();
    }

    // ✅ Recreate AWS IoT
    final awsService = Get.put(
      AwsIotService(
        onMessage: (topic, data) => print('📩 $topic → $data'),
        onConnectionStatus: (status) => print('🔌 $status'),
      ),
      permanent: true,
    );

    await Future.delayed(const Duration(seconds: 1));
    await awsService.connect();

    setState(() => _isLoading = false);

    Get.offAll(() => const DashboardScreen());
  }

  // -------------------------------------------------------------
  // 🧹 Clean up controllers
  // -------------------------------------------------------------
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // 🖼️ UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8.0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Elevate.ai',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Username
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Username or Email',
                        labelStyle: TextStyle(color: accentColor.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.person, color: accentColor),
                        filled: true,
                        fillColor: backgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: accentColor.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.lock, color: accentColor),
                        filled: true,
                        fillColor: backgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Forgot Password / Create Account
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: accentColor, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Create an Account',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
