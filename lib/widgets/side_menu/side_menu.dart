import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart' as app_colors;
import '../../data/menu_data.dart';
import '../../services/storage_service.dart';
import 'menu_item.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuItemSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: app_colors.darkBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.white, size: 24),
                const Spacer(),
                Text(
                  'Elevate Cloud',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.folder_open_outlined,
                    color: Colors.white, size: 24),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(MenuData.menuItems.length, (index) {
                      final item = MenuData.menuItems[index];
                      return MenuItemWidget(
                        icon: item.icon,
                        text: item.text,
                        hasIndicator: item.hasIndicator,
                        hasTrailingIcon: item.hasTrailingIcon,
                        isSelected: selectedIndex == index,
                        onTap: () => onMenuItemSelected(index),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
                      child: Text(
                        'Administration',
                        style: TextStyle(
                            color: app_colors.slateGrey.withOpacity(0.7),
                            fontSize: 12),
                      ),
                    ),
                    ...List.generate(MenuData.adminMenuItems.length, (index) {
                      final item = MenuData.adminMenuItems[index];
                      final adminIndex =
                          MenuData.menuItems.length + index; // continues index
                      return MenuItemWidget(
                        icon: item.icon,
                        text: item.text,
                        isSelected: selectedIndex == adminIndex,
                        onTap: () => onMenuItemSelected(adminIndex),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: app_colors.mediumBlue, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logout Button (centered and minimal)
                ElevatedButton.icon(
                  onPressed: () async {
                    await StorageService.clearLogin();
                    Get.offAllNamed('/login'); // Navigate back to login
                  },
                  icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Copyright
                Center(
                  child: Text(
                    'ELEVATE © 2025',
                    style: TextStyle(color: app_colors.slateGrey, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 4),
                // Version text
                Center(
                  child: Text(
                    '6.5.10-beta',
                    style: TextStyle(color: app_colors.slateGrey, fontSize: 11),
                  ),
                ),
              ],
            ),
          )

        ],
      ),
    );
  }
}
