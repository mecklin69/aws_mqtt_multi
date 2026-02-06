import 'package:Elevate/screens/DeviceSettings.dart';
import 'package:Elevate/widgets/dashboard/Alarms.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart' as app_colors;
import '../responsive/responsive_layout.dart';
import '../widgets/side_menu/side_menu.dart';
import '../widgets/dashboard/main_content.dart';
import '../widgets/dashboard/connected_devices_location.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  // You can replace these with more detailed pages later.
  final List<Widget> pages = const [
    MainContent(),
    ConnectedDevicesLocation(),
    Center(child: Text('Dashboards Page')),
    Center(child: Text('Data Buckets Page')),
    Center(child: Text('Endpoints Page')),
 AlarmsPage(),
    Center(child: Text('Access Tokens Page')),
    Center(child: Text('Assets Page')),
    FirmwareFlashPage(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !Responsive.isDesktop(context)
          ? AppBar(
        backgroundColor: app_colors.darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Elevate Engineers',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
      drawer: Drawer(
        child: SideMenu(
          selectedIndex: selectedIndex,
          onMenuItemSelected: (index) {
            setState(() => selectedIndex = index);
            Navigator.pop(context); // close drawer on mobile
          },
        ),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              SideMenu(
                selectedIndex: selectedIndex,
                onMenuItemSelected: (index) {
                  setState(() => selectedIndex = index);
                },
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: pages[selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
