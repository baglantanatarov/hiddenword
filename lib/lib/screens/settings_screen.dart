
import 'package:flutter/material.dart';
import 'package:jasyrin_soz/services/settings_repo.dart';
import 'package:jasyrin_soz/widgets/gradient_bg.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _sound = await SettingsRepo().getSoundEnabled();
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await SettingsRepo().setSoundEnabled(_sound);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Баптаулар')),
      body: GradientBg(
        child: _loaded
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: SwitchListTile.adaptive(
                      title: const Text('Дыбыс қосу/сөндіру'),
                      subtitle: const Text('Дұрыс/қате дыбыстары'),
                      value: _sound,
                      onChanged: (v) => setState(() => _sound = v),
                      activeColor: const Color(0xFF3DDC84),
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassButton(label: 'Сақтау', icon: Icons.save_rounded, onTap: _save),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
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
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0,10))],
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 26, color: Colors.white),
              const SizedBox(width: 10),
              Text(widget.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
