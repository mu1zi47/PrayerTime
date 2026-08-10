import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../data/azan_sounds.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/prayer_icon.dart';

class AzanPlayingScreen extends StatefulWidget {
  final PrayerKind kind;
  final String azanSoundId;

  const AzanPlayingScreen({
    super.key,
    required this.kind,
    required this.azanSoundId,
  });

  @override
  State<AzanPlayingScreen> createState() => _AzanPlayingScreenState();
}

class _AzanPlayingScreenState extends State<AzanPlayingScreen> {
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    try {
      await _player.setAsset(AzanSounds.assetFor(widget.azanSoundId));
      await _player.play();
    } catch (_) {
      // Nothing to play — the screen still lets the user dismiss cleanly.
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) => _player.stop(),
        child: Builder(
          builder: (context) {
            final t = AppLocalizations.of(context)!;
            // No SafeArea — the accent background should bleed edge-to-edge
            // behind the transparent status/navigation bars; only the
            // content itself needs the inset, added straight into the
            // padding below.
            final padding = MediaQuery.paddingOf(context);
            return Scaffold(
              backgroundColor: AppColors.accent,
              body: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24 + padding.top,
                  24,
                  24 + padding.bottom,
                ),
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                iconForPrayer(widget.kind),
                                size: 56,
                                color: AppColors.bg,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                t.prayerTimeLabel,
                                style:
                                    AppTextStyles.body(
                                      fontSize: 14,
                                      color: AppColors.bg,
                                    ).copyWith(
                                      color: AppColors.bg.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nameForPrayer(t, widget.kind),
                                style: AppTextStyles.heading(
                                  fontSize: 34,
                                  color: AppColors.bg,
                                ),
                              ),
                              Text(
                                arabicForPrayer(widget.kind),
                                textDirection: TextDirection.rtl,
                                style:
                                    AppTextStyles.body(
                                      fontSize: 16,
                                      color: AppColors.bg,
                                    ).copyWith(
                                      color: AppColors.bg.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _stop,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.stop_rounded,
                            size: 36,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.stopButton,
                        style: AppTextStyles.body(
                          fontSize: 13,
                          color: AppColors.bg,
                        ).copyWith(color: AppColors.bg.withValues(alpha: 0.85)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
