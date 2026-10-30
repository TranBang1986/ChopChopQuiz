import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'stats_service.dart';

enum MusicTrack { menu, game }

/// Nhạc CC0: Ruskerdax — Happy Vibes (menu), Puzzling (play) trên OpenGameArt.
/// SFX CC0: Kenney Interface Sounds (kenney.nl). Không bắt buộc ghi công.
class AudioService with WidgetsBindingObserver {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _music = AudioPlayer();
  final Map<String, AudioPlayer> _clips = {};
  final Map<String, DateTime> _readyAt = {};

  bool _ready = false;
  bool _observing = false;
  bool _suspended = false;
  MusicTrack? _track;
  String? _musicFile;

  static bool get _inWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');

  AudioContext get _mixContext => AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      );

  AudioContext get _musicContext => AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
      );

  Future<void> init() async {
    if (_ready || _inWidgetTest) return;
    try {
      await AudioPlayer.global.setAudioContext(_mixContext);
      await _music.setAudioContext(_musicContext);
      await _music.setPlayerMode(PlayerMode.mediaPlayer);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.38);
      if (!_observing) {
        _observing = true;
        WidgetsBinding.instance.addObserver(this);
      }
      _ready = true;
    } catch (e) {
      debugPrint('AudioService.init: $e');
    }
  }

  void playMusic(MusicTrack track) {
    if (_inWidgetTest) return;
    _track = track;
    unawaited(_startMusic(track));
  }

  Future<void> _startMusic(MusicTrack track) async {
    await init();
    if (!_ready || _track != track || !StatsService.instance.musicOn || _suspended) return;
    final file = track == MusicTrack.menu ? 'music_menu.mp3' : 'music_game.mp3';
    try {
      if (_musicFile == file) {
        if (_music.state != PlayerState.playing) {
          try {
            await _music.resume();
          } catch (_) {
            await _music.play(AssetSource('audio/$file'));
          }
        }
        return;
      }
      _musicFile = file;
      await _music.play(AssetSource('audio/$file'));
      await _music.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('music $file: $e');
    }
  }

  Future<void> setMusicEnabled(bool on) async {
    StatsService.instance.musicOn = on;
    if (!on) {
      await _music.pause();
      return;
    }
    final track = _track;
    if (track != null) {
      _musicFile = null;
      await _startMusic(track);
    }
  }

  Future<void> setSoundEnabled(bool on) async {
    StatsService.instance.soundOn = on;
  }

  Future<void> pauseForAd() async {
    _suspended = true;
    await _music.pause();
  }

  Future<void> resumeAfterAd() async {
    _suspended = false;
    final track = _track;
    if (track != null && StatsService.instance.musicOn) await _startMusic(track);
  }

  void play(String file, {double volume = 1, Duration gap = Duration.zero}) {
    if (_inWidgetTest || !StatsService.instance.soundOn || _suspended) return;
    final now = DateTime.now();
    final readyAt = _readyAt[file];
    if (readyAt != null && now.isBefore(readyAt)) return;
    if (gap > Duration.zero) _readyAt[file] = now.add(gap);
    unawaited(_fire(file, volume));
  }

  Future<void> _fire(String file, double volume) async {
    if (_suspended) return;
    try {
      await init();
      final player = _clips[file] ??= await _makeSfx();
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource('audio/$file'));
    } catch (e) {
      debugPrint('sfx $file: $e');
    }
  }

  Future<AudioPlayer> _makeSfx() async {
    final player = AudioPlayer();
    await player.setAudioContext(_mixContext);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  void tap() => play('tap.wav', volume: 0.55, gap: const Duration(milliseconds: 70));

  void start() => play('start.wav', volume: 0.85);

  void correct() => play('correct.wav', volume: 0.9);

  void wrong() => play('wrong.wav', volume: 0.85);

  void bonus() => play('bonus.wav', volume: 0.88);

  void finish({required bool record}) =>
      play(record ? 'highscore.wav' : 'finish.wav', volume: 0.95);

  void tick({required bool urgent}) => play(
        urgent ? 'tick_urgent.wav' : 'tick.wav',
        volume: urgent ? 1 : 0.75,
        gap: const Duration(milliseconds: 180),
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _suspended = false;
      final track = _track;
      if (track != null && StatsService.instance.musicOn) unawaited(_startMusic(track));
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _suspended = true;
      unawaited(_music.pause());
      for (final player in _clips.values) {
        unawaited(player.stop());
      }
    }
  }
}
