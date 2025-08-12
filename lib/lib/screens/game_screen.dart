
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jasyrin_soz/data/dictionary.dart';
import 'package:jasyrin_soz/services/audio_service.dart';
import 'package:jasyrin_soz/widgets/gradient_bg.dart';

class GameScreen extends StatefulWidget {
  final DictData dict;
  final bool soundEnabled;
  const GameScreen({super.key, required this.dict, required this.soundEnabled});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late String _secretOrig;
  late String _secretCat;
  final TextEditingController _controller = TextEditingController();
  final List<Guess> _guesses = [];
  final Set<String> _seen = {};
  late final AudioService _audio;

  late AnimationController _pulse;
  double _lastPercent = 0;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _audio = AudioService()..enabled = widget.soundEnabled;
    _startNewSecret();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  void _startNewSecret() {
    _secretOrig = widget.dict.nextSecret();
    _secretCat = widget.dict.categoryOf(_secretOrig);
    _guesses.clear();
    _seen.clear();
    _lastPercent = 0;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    _controller.clear();

    final strict = DictData.normalizeStrict(raw);
    if (_seen.contains(strict)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Бұл сөзді бұрын енгіздің', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent.shade200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _seen.add(strict);

    final p = widget.dict.similarityPercent(raw, _secretOrig);
    final win = DictData.normalizeLoose(raw) == DictData.normalizeLoose(_secretOrig);

    setState(() {
      _guesses.add(Guess(raw, p));
      _guesses.sort((a, b) => b.percent.compareTo(a.percent));
      _lastPercent = (_guesses.isEmpty ? 0 : _guesses.first.percent).toDouble();
    });

    if (win) {
      _audio.correct();
      HapticFeedback.mediumImpact();
      _showWinDialog();
    } else {
      if (p >= 70) {
        _pulse.forward(from: 0);
        _audio.near();
      } else if (p >= 40) {
        _audio.near();
      } else {
        _audio.wrong();
      }
      HapticFeedback.selectionClick();
    }
  }

  String _labelFor(int p) {
    if (p >= 70) return 'Жақын';
    if (p >= 40) return 'Жақынырақ';
    return 'Қашық';
  }

  List<String> _buildHints() {
    final list = <String>[];
    switch (_secretCat) {
      case 'адам_денесі':
        list.add('Ол адам денесіндегі нәрсе болуы мүмкін.');
        break;
      case 'жануар':
        list.add('Бұл тірі жанға қатысты.');
        break;
      case 'табиғат':
        list.add('Табиғатқа байланысты.');
        break;
      case 'киім':
        list.add('Киім-кешекке қатысты болуы ықтимал.');
        break;
      case 'тұрмыс':
        list.add('Тұрмыстық зат болуы мүмкін.');
        break;
      case 'көлік':
        list.add('Көлікке немесе жолға қатысы бар.');
        break;
      case 'тағам':
        list.add('Ас-тағамға қатысты.');
        break;
      case 'техника':
        list.add('Техника/құрылғы болуы ықтимал.');
        break;
      default:
        list.add('Жалпы қолданылатын нәрсе.');
    }
    final len = _secretOrig.length;
    if (len > 1) list.add('Ұзындығы: $len әріп.');
    final first = _secretOrig[0].toUpperCase();
    list.add('Бірінші әрпі: $first...');
    return list;
  }

  void _openUnifiedModal({required String title, required IconData icon, required Color iconColor, required List<String> lines}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141827),
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              ...lines.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(h)),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _openHintModal() => _openUnifiedModal(
    title: 'Кеңес',
    icon: Icons.lightbulb_rounded,
    iconColor: const Color(0xFFFFD54F),
    lines: _buildHints(),
  );

  void _openInfo() => _openUnifiedModal(
    title: 'Ойын туралы',
    icon: Icons.info_outline_rounded,
    iconColor: Colors.blueAccent,
    lines: const [
      'Сөз енгізіңіз — пайыз жақындаған сайын өседі.',
      'Категория және әріп ұқсастығы әсер етеді.',
      'Enter/Done арқылы жіберуге болады.'
    ],
  );

  void _showWinDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Win',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        );
        final screenW = MediaQuery.of(ctx).size.width;
        final dialogW = screenW * 0.92 > 520 ? 520.0 : screenW * 0.92;
        return SlideTransition(
          position: slide,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: dialogW,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B2136), Color(0xFF161A2B)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 28, offset: Offset(0,12))],
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 66, color: Color(0xFF3DDC84)),
                      const SizedBox(height: 8),
                      const Text('Керемет!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, decoration: TextDecoration.none)),
                      const SizedBox(height: 8),
                      const Text('Жасырынған сөз:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, decoration: TextDecoration.none)),
                      const SizedBox(height: 4),
                      Text(
                        _secretOrig.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlassIconButton(
                            icon: Icons.refresh_rounded,
                            tooltip: 'Қайта ойнау',
                            onTap: () {
                              Navigator.pop(context);
                              WidgetsBinding.instance.addPostFrameCallback((_) => _startNewSecret());
                            },
                          ),
                          const SizedBox(width: 12),
                          _GlassIconButton(
                            icon: Icons.home_rounded,
                            tooltip: 'Басты бет',
                            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final barColor = Color.lerp(Colors.red, Colors.green, _lastPercent/100) ?? Colors.green;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Сөзді тап'),
        leading: IconButton(
          tooltip: 'Басты бет',
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        actions: [
          IconButton(
            tooltip: 'Кеңес',
            icon: const Icon(Icons.lightbulb_rounded),
            onPressed: _openHintModal,
          ),
          IconButton(
            tooltip: 'Ақпарат',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _openInfo,
          ),
          IconButton(
            tooltip: 'Қайта бастау',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _startNewSecret,
          ),
        ],
      ),
      body: GradientBg(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onEditingComplete: _submit,
                        decoration: const InputDecoration(
                          hintText: 'Болжамды сөзді енгіз',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (MediaQuery.of(context).size.width - 64) * (_lastPercent / 100.0),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              if (_controller.text.isEmpty && _guesses.isEmpty)
                Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: 0.7,
                      child: const Text('Әр түрлі болжамдағы сөздерді жаз', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                    ),
                  ),
                )
              else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ListView.builder(
                    itemCount: _guesses.length,
                    itemBuilder: (context, i) {
                      final g = _guesses[i];
                      final color = Color.lerp(Colors.red, Colors.green, g.percent/100)!;
                      final tile = Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color, child: Text('${g.percent}%', style: const TextStyle(color: Colors.white))),
                          title: Text(g.word, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                          subtitle: Text(_labelFor(g.percent), style: const TextStyle(color: Colors.white70)),
                          trailing: Icon(
                            g.percent >= 70 ? Icons.star_rounded :
                            g.percent >= 40 ? Icons.trending_up : Icons.trending_down,
                            color: color,
                          ),
                        ),
                      );
                      if (g.percent >= 70) {
                        return ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.03).animate(
                            CurvedAnimation(parent: _pulse, curve: Curves.easeOut)),
                          child: tile,
                        );
                      }
                      return tile;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }


@override
Widget build(BuildContext context) {
  return ScaleTransition(
    scale: Tween(begin: 1.0, end: 0.95).animate(_c),
    child: Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTapDown: (_) => _c.forward(),
        onTapCancel: () => _c.reverse(),
        onTap: () { _c.reverse(); widget.onTap(); },
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 18, offset: const Offset(0,8))],
          ),
          child: Icon(widget.icon, color: Colors.white),
        ),
      ),
    ),
  );
}

}
