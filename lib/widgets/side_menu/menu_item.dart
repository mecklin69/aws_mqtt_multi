import 'package:flutter/material.dart';
import '../../constants/app_colors.dart' as app_colors;

class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool hasIndicator;
  final bool hasTrailingIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.hasIndicator = false,
    this.hasTrailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? app_colors.activeBlue.withOpacity(0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (hasIndicator)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: app_colors.indicatorOrange,
                  shape: BoxShape.circle,
                ),
              ),
            if (hasTrailingIcon)
              Icon(
                Icons.chevron_right,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
