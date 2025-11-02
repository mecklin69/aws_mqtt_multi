import 'package:flutter/material.dart';
import '../../constants/app_colors.dart' as app_colors;

class StatCircle extends StatelessWidget {
  final int value;
  final int total;
  final String label;

  const StatCircle(
      {super.key,
      required this.value,
      required this.total,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final double percentage = total == 0 ? 0.0 : value / total;

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: percentage),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor:
                          app_colors.slateGrey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          app_colors.activeBlue),
                    );
                  },
                ),
              ),
              Text(
                '$value/$total',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: app_colors.activeBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                color: app_colors.slateGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
