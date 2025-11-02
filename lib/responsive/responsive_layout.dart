import 'package:flutter/material.dart';

/// A helper class to manage responsive layouts.
/// It provides static methods to check the screen size.
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;
}
