import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/azan_sounds.dart';
import '../models/azan_sound.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

/// Reciter picker. Tapping a row selects it (persisted) and starts a
/// looping preview so the user immediately hears what they picked;
/// tapping the same, currently-playing row again just stops the preview.
class AzanScreen extends StatefulWidget {
  final AppState appState;

  const AzanScreen({super.key, required this.appState});

  @override
  State<AzanScreen> createState() => _AzanScreenState();
}

class _AzanScreenState extends State<AzanScreen> {
  final _player = AudioPlayer();
  String? _playingId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _tap(AzanSound sound) async {
    if (_playingId == sound.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }

    widget.appState.selectAzanSound(sound.id);
    setState(() => _playingId = sound.id);
    try {
      await _player.setLoopMode(LoopMode.one);
      await _player.setAsset(AzanSounds.assetFor(sound.id));
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status/navigation bars.
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, padding.bottom + 18),
            children: [
              Row(
                children: [
                  ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text('Азан', style: AppTextStyles.heading(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Пока у всех чтецов звучит один и тот же временный сигнал — '
                  'настоящие записи будут добавлены позже.',
                  style: AppTextStyles.body(fontSize: 12, color: AppColors.text).copyWith(
                    color: AppColors.text.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final sound in AzanSounds.all)
                _AzanRow(
                  sound: sound,
                  selected: sound.id == widget.appState.azanSoundId,
                  playing: sound.id == _playingId,
                  onTap: () => _tap(sound),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AzanRow extends StatelessWidget {
  final AzanSound sound;
  final bool selected;
  final bool playing;
  final VoidCallback onTap;

  const _AzanRow({required this.sound, required this.selected, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent100 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: playing ? AppColors.accent : AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 16,
                  color: playing ? AppColors.bg : AppColors.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sound.reciterName, style: AppTextStyles.heading(fontSize: 14)),
                    if (sound.note != null)
                      Text(
                        sound.note!,
                        style: AppTextStyles.body(fontSize: 11, color: AppColors.text).copyWith(
                          color: AppColors.text.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
