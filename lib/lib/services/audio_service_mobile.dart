
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  bool enabled = true;
  Future<void> _play(String asset) async {
    if (!enabled) return;
    final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    try {
      await p.play(AssetSource(asset));
    } catch (_) {} finally { p.dispose(); }
  }
  Future<void> correct() => _play('assets/sfx/correct.wav');
  Future<void> near()    => _play('assets/sfx/near.wav');
  Future<void> wrong()   => _play('assets/sfx/wrong.wav');
}
