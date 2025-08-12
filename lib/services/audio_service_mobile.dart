import 'package:audioplayers/audioplayers.dart';

class AudioService {
  bool enabled = true;
  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  Future<void> _play(String assetPath) async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource(assetPath)); // 'sfx/...'
    } catch (_) {}
  }

  Future<void> correct() => _play('sfx/correct.wav');
  Future<void> near()    => _play('sfx/near.wav');
  Future<void> wrong()   => _play('sfx/wrong.wav');
}
