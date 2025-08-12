import 'package:flutter/material.dart';
import 'package:jasyrin_soz/data/dictionary.dart';
import 'package:jasyrin_soz/screens/game_screen.dart';
import 'package:jasyrin_soz/screens/settings_screen.dart';
import 'package:jasyrin_soz/widgets/gradient_bg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sound = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF3DDC84)],
                  ).createShader(r),
                  child: const Text('Жасырын сөз',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text('Жасырын сөзді тап! Жақындау пайызын бақыла.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85)), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                _GlassButton(
                  label: 'Ойын бастау',
                  icon: Icons.play_arrow_rounded,
                  onTap: () async {
                    final dict = await DictData.load();
                    if (!context.mounted) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => GameScreen(dict: dict, soundEnabled: _sound),
                    ));
                  },
                ),
                const SizedBox(height: 12),
                _GlassButton(
                  label: 'Баптаулар',
                  icon: Icons.settings_rounded,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 150)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.97).animate(_c),
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
