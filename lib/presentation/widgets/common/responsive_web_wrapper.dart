import 'package:flutter/material.dart';

class ResponsiveWebWrapper extends StatelessWidget {
  const ResponsiveWebWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Direct passthrough to let the app scale and occupy 100% width and height on desktop web
    return child;
  }
}
