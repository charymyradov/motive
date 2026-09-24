import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralised sound-effect player. Every SFX lives in `assets/audio/sfx/`.
///
/// Register as a lazy singleton in GetIt and call the short helpers from
/// anywhere in the presentation layer.
class SoundService {
  SoundService() : _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  final AudioPlayer _player;

  /// Whether sounds are enabled (toggled by the user via settings).
  bool enabled = true;

  Future<void> _play(String asset) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/sfx/$asset'));
    } catch (e) {
      debugPrint('SoundService: failed to play $asset – $e');
    }
  }

  // ── Game ──────────────────────────────────────────────────────────────
  void playSwipe() => _play('card_swipe.mp3');
  void playCorrect() => _play('correct_answer.mp3');
  void playWrong() => _play('wrong_answer.mp3');
  void playUnlock() => _play('card_unlock.mp3');
  void playFlip() => _play('card_flip.mp3');
  void playConfetti() => _play('confetti.mp3');
  void playXpGain() => _play('xp_gain.mp3');
  void playLevelUp() => _play('level_up.mp3');

  // ── Analyzer ──────────────────────────────────────────────────────────
  void playScanStart() => _play('scan_start.mp3');
  void playScanComplete() => _play('scan_complete.mp3');
  void playImageAttached() => _play('image_attached.mp3');
  void playAnalysisDelete() => _play('analysis_delete.wav');

  // ── UI ────────────────────────────────────────────────────────────────
  void playTabSwitch() => _play('tab_switch.mp3');
  void playButtonPress() => _play('button_press.mp3');
  void playToggleClick() => _play('toggle_click.mp3');
  void playSheetOpen() => _play('sheet_open.mp3');
  void playPullRefresh() => _play('pull_refresh.wav');
  void playNotificationTap() => _play('notification_tap.mp3');

  // ── Onboarding ────────────────────────────────────────────────────────
  void playStepAdvance() => _play('step_advance.mp3');
  void playArenaSelect() => _play('arena_select.wav');
  void playOnboardingComplete() => _play('onboarding_complete.mp3');

  void dispose() => _player.dispose();
}
