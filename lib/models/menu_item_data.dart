import 'package:flutter/material.dart';

// Data model for a single menu item.
class MenuItemData {
  final IconData icon;
  final String text;
  final bool hasIndicator;
  final bool hasTrailingIcon;

  MenuItemData({
    required this.icon,
    required this.text,
    this.hasIndicator = false,
    this.hasTrailingIcon = false,
  });
}
