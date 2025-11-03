import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_screen.dart';
import '../services/storage_service.dart';

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

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username == "admin" && password == "1234") {
      // ✅ Save login state
      await StorageService.saveLogin(username);

      Get.offAll(() => const DashboardScreen());
    } else {
      Get.snackbar(
        "Login Failed",
        "Invalid username or password",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

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
                padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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

                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Username or Email',
                        labelStyle:
                        TextStyle(color: accentColor.withOpacity(0.7)),
                        prefixIcon:
                        const Icon(Icons.person, color: accentColor),
                        filled: true,
                        fillColor: backgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle:
                        TextStyle(color: accentColor.withOpacity(0.7)),
                        prefixIcon:
                        const Icon(Icons.lock, color: accentColor),
                        filled: true,
                        fillColor: backgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

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
                        onPressed: _handleLogin,
                        child: const Text(
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

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Forgot Password button (left-aligned)
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

                              // Spacer to avoid cramping
                              const SizedBox(width: 8),

                              // Create Account button (right-aligned)
                              FittedBox(
                                fit: BoxFit.scaleDown, // auto-shrink if needed
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
