import 'package:just_audio/just_audio.dart';

class EffectsPlayer {
  final AudioPlayer _dingPlayer;

  /// Don't forget to call [dispose] when you're done with this object.
  EffectsPlayer() : _dingPlayer = AudioPlayer() {
    _dingPlayer.setAsset('assets/ding.mp3');
  }

  void dispose() {
    _dingPlayer.dispose();
  }

  void playDing() {
    _play(_dingPlayer);
  }

  Future<void> _play(AudioPlayer player) async {
    if (![
      ProcessingState.ready,
      ProcessingState.completed,
    ].contains(player.playerState.processingState)) {
      return;
    }

    await player.pause();
    await player.seek(Duration.zero);
    return player.play();
  }
}
