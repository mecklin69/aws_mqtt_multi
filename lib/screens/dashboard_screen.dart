import 'package:Elevate/services/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart' as app_colors;
import '../responsive/responsive_layout.dart';
import '../widgets/side_menu/side_menu.dart';
import '../widgets/dashboard/main_content.dart';
import '../widgets/dashboard/connected_devices_location.dart';
import '../widgets/dashboard/Alarms.dart';
import 'DataBucketPage.dart';
import 'DeviceSettings.dart';
// Ensure this import points to your FirmwareFlashPage file
// import 'package:Elevate/screens/FirmwareFlashPage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  // 1. Declare the list here
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 2. Initialize pages ONCE. These instances will now live
    // for the entire lifetime of the DashboardScreen.
    _pages = [
      const MainContent(),
      const ConnectedDevicesLocation(),
      const Center(child: Text('Dashboards Page')),
      const DataBucketPage(),
      EndpointsPage(),
      const AlarmsPage(),
      const Center(child: Text('Access Tokens Page')),
      const Center(child: Text('Assets Page')),
      const FirmwareFlashPage(),
    ];
  }

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
              child: IndexedStack(
                index: selectedIndex,
                children: _pages, // Use the persisted list
              ),
            ),
          ],
        ),
      ),
    );
  }
}