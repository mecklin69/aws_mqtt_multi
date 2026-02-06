import 'dart:io';
import 'package:Elevate/services/amplify_service.dart';
import 'package:Elevate/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ Add this
import 'package:Elevate/services/aws_iot_services.dart';
import 'package:Elevate/services/storage_service.dart';
import 'constants/app_colors.dart' as app_colors;
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize local storage
try{
  if(Platform.isWindows) {
    await NotificationService.init();
  }
}catch(e){}
  await StorageService.init();
  await AmplifyService.configure();
  // ✅ Initialize notifications

if (Platform.isAndroid) {
  await NotificationService.init();}

  // ✅ Handle notification permissions cross-platform
  if (Platform.isAndroid) {
    // Android 13+ (API 33) needs explicit permission
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('✅ Notification permission granted');
    } else {
      print('⚠️ Notification permission denied');
    }

  } else if (Platform.isIOS) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ✅ Initialize AWS IoT service before app runs
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
      // ✅ Conditionally show dashboard or login based on stored login
      home: isUserLoggedIn ? const DashboardScreen() : const LoginPage(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
      ],
    );
  }
}
