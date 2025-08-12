
import 'package:flutter/material.dart';

class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B0D14), Color(0xFF13192B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
