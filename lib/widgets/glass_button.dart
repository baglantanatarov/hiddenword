import 'package:flutter/material.dart';

/// Reusable glassmorphism button to avoid duplication (DRY).
class GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const GlassButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
      child: InkWell(
        onTapDown: (_) => _c.forward(),
        onTapCancel: () => _c.reverse(),
        onTap: () { _c.reverse(); widget.onTap(); },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0,10))],
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 26, color: Colors.white),
            const SizedBox(width: 10),
            Text(widget.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}
