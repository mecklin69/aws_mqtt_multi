import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvino/services/aws_iot_services.dart';
import 'package:marvino/services/storage_service.dart';
import 'constants/app_colors.dart' as app_colors;
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  // Initialize AWS IoT service before app runs
  final AwsIotService awsService = Get.put(AwsIotService());
  await awsService.connect();
  // ✅ Determine login state before app starts
  final bool isUserLoggedIn = StorageService.isLoggedIn();
  runApp(ThingerDashboardApp(isUserLoggedIn: isUserLoggedIn));
}

class ThingerDashboardApp extends StatelessWidget {
  final bool isUserLoggedIn;
  const ThingerDashboardApp({super.key, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elevate Cloud Services',
      theme: ThemeData(
        scaffoldBackgroundColor: app_colors.lightGrey,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      // Start with login page
      // ✅ Conditionally show dashboard or login based on stored login
      home: isUserLoggedIn ? const DashboardScreen() : const LoginPage(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
      ],
    );
  }
}
