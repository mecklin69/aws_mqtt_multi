import 'package:flutter/material.dart';
import '../models/menu_item_data.dart';


class MenuData {
  static final List<MenuItemData> menuItems = [
    MenuItemData(icon: Icons.bar_chart, text: 'Statistics'),
    MenuItemData(
        icon: Icons.developer_board, text: 'Devices', hasIndicator: true),
    MenuItemData(icon: Icons.dashboard, text: 'Dashboards'),
    MenuItemData(icon: Icons.data_usage, text: 'Data Buckets'),
    MenuItemData(icon: Icons.gps_fixed, text: 'Endpoints'),
    MenuItemData(icon: Icons.notifications, text: 'Alarms'),
    MenuItemData(icon: Icons.vpn_key, text: 'Access Tokens'),
    MenuItemData(icon: Icons.layers, text: 'Assets'),
    MenuItemData(icon: Icons.folder, text: 'File Storages'),
    MenuItemData(
        icon: Icons.workspaces, text: 'Products', hasIndicator: true),
    MenuItemData(
        icon: Icons.rocket_launch, text: 'Projects', hasIndicator: true),
    MenuItemData(icon: Icons.extension, text: 'Plugins'),
    MenuItemData(icon: Icons.build, text: 'Toolbox', hasTrailingIcon: true),
  ];

  static final List<MenuItemData> adminMenuItems = [
    MenuItemData(icon: Icons.people, text: 'User Accounts'),
    MenuItemData(icon: Icons.dns, text: 'Cluster Hosts'),
  ];
}
