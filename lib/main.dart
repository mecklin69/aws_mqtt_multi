import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvino/services/aws_iot_services.dart';
import 'constants/app_colors.dart' as app_colors;
import 'screens/dashboard_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AwsIotService awsService = Get.put(AwsIotService());
  await awsService.connect();
  runApp(const ThingerDashboardApp());
}

class ThingerDashboardApp extends StatelessWidget {
  const ThingerDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elevate Cloud Services',
      theme: ThemeData(
        scaffoldBackgroundColor: app_colors.lightGrey,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const DashboardScreen(),
    );
  }
}
