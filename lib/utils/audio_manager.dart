// lib/utils/audio_manager.dart
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'preferences.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  final _ping = AudioPlayer();
  final _boom = AudioPlayer();
  final _win = AudioPlayer();
  final _music = AudioPlayer();
  bool _ready = false;

  Future<void> init() async {
    try {
      await _ping.setSource(AssetSource('sounds/ping.wav'));
      await _boom.setSource(AssetSource('sounds/boom.wav'));
      await _win.setSource(AssetSource('sounds/complete.wav'));
      _ready = true;
    } catch (_) {}
    startMusic();
  }

  bool get _soundOn => Preferences.instance.isSoundEnabled();
  bool get _musicOn => Preferences.instance.isMusicEnabled();

  Future<void> startMusic() async {
    if (!_musicOn) return;
    try {
      final track = 1 + Random().nextInt(3);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.35);
      await _music.play(AssetSource('music/ambient_$track.wav'));
    } catch (_) {}
  }

  Future<void> stopMusic() async => _music.stop();

  Future<void> _play(AudioPlayer p) async {
    if (!_ready || !_soundOn) return;
    await p.stop();
    await p.resume();
  }

  Future<void> playPing() => _play(_ping);
  Future<void> playBoom() => _play(_boom);
  Future<void> playComplete() => _play(_win);
}
