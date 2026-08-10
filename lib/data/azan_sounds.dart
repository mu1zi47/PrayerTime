import '../l10n/app_localizations.dart';
import '../models/azan_sound.dart';

class AzanSounds {
  AzanSounds._();

  static const placeholderAsset = 'assets/audio/azan_placeholder.wav';

  static const List<AzanSound> all = [
    AzanSound(id: 'abdulbasit'),
    AzanSound(id: 'aknazar'),
    AzanSound(id: 'ali_ahmed_mulla'),
    AzanSound(id: 'ahmed_al_nufais'),
    AzanSound(id: 'baubek'),
    AzanSound(id: 'mustafa_ismail'),
    AzanSound(id: 'mishari'),
    AzanSound(id: 'mishari_takbir_short'),
    AzanSound(id: 'mustafa_ozcan'),
    AzanSound(id: 'mansur_zahrani'),
    AzanSound(id: 'nasir_qatami'),
    AzanSound(id: 'raad_kurdi'),
    AzanSound(id: 'ahmed_al_nufais_2'),
    AzanSound(id: 'saidmuhammed'),
  ];

  static AzanSound byId(String id) => all.firstWhere((s) => s.id == id, orElse: () => all.first);

  static String assetFor(String id) => placeholderAsset;
}

String reciterNameFor(AppLocalizations t, String soundId) => switch (soundId) {
      'abdulbasit' => t.reciterAbdulbasit,
      'aknazar' => t.reciterAknazar,
      'ali_ahmed_mulla' => t.reciterAliAhmedMulla,
      'ahmed_al_nufais' || 'ahmed_al_nufais_2' => t.reciterAhmedAlNufais,
      'baubek' => t.reciterBaubek,
      'mustafa_ismail' => t.reciterMustafaIsmail,
      'mishari' || 'mishari_takbir_short' => t.reciterMishari,
      'mustafa_ozcan' => t.reciterMustafaOzcan,
      'mansur_zahrani' => t.reciterMansurZahrani,
      'nasir_qatami' => t.reciterNasirQatami,
      'raad_kurdi' => t.reciterRaadKurdi,
      'saidmuhammed' => t.reciterSaidmuhammed,
      _ => soundId,
    };

String? reciterNoteFor(AppLocalizations t, String soundId) => switch (soundId) {
      'mishari_takbir_short' => t.reciterNoteTakbirShort,
      'ahmed_al_nufais_2' => t.reciterNoteStudioRecording,
      _ => null,
    };
