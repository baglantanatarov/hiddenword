
import 'dart:web_audio';

class AudioService {
  bool enabled = true;
  final AudioContext _ctx = AudioContext();
  Future<void> _beep(double f, int ms) async {
    if (!enabled) return;
    final osc = _ctx.createOscillator();
    final gain = _ctx.createGain();
    osc.type = 'sine';
    osc.frequency!.value = f;
    gain.gain!.value = 0.12;
    osc.connectNode(gain); gain.connectNode(_ctx.destination!);
    final now = _ctx.currentTime!;
    osc.start2(0); osc.stop(now + ms / 1000.0);
  }
  Future<void> correct() => _beep(990, 180);
  Future<void> near()    => _beep(660, 140);
  Future<void> wrong()   => _beep(250, 160);
}
