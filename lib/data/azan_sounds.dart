import '../models/azan_sound.dart';

/// Реестр чтецов азана. Все записи сейчас звучат одним и тем же
/// сгенерированным тоном-заглушкой ([placeholderAsset]) — реальные записи
/// конкретных чтецов защищены авторским правом и не могут быть встроены
/// без лицензии. Чтобы подставить настоящую запись, положи файл в
/// `assets/audio/<id>.mp3`, зарегистрируй его в pubspec.yaml и укажи
/// путь в [AzanSounds.assetFor].
class AzanSounds {
  AzanSounds._();

  static const placeholderAsset = 'assets/audio/azan_placeholder.wav';

  static const List<AzanSound> all = [
    AzanSound(id: 'abdulbasit', reciterName: 'Абдульбасит Абдуссамат'),
    AzanSound(id: 'aknazar', reciterName: 'Акназар Маратулы'),
    AzanSound(id: 'ali_ahmed_mulla', reciterName: 'Али Ахмед Мулла'),
    AzanSound(id: 'ahmed_al_nufais', reciterName: 'Ахмед аль-Нуфайс'),
    AzanSound(id: 'baubek', reciterName: 'Баубек Бердыгалиулы'),
    AzanSound(id: 'mustafa_ismail', reciterName: 'Мустафа Исмаил'),
    AzanSound(id: 'mishari', reciterName: 'Мишари Рашид аль-Афаси'),
    AzanSound(
      id: 'mishari_takbir_short',
      reciterName: 'Мишари Рашид аль-Афаси',
      note: 'такбир, короткая версия',
    ),
    AzanSound(id: 'mustafa_ozcan', reciterName: 'Мустафа Осджан Гунешдогды'),
    AzanSound(id: 'mansur_zahrani', reciterName: 'Мансур аз-Захрани'),
    AzanSound(id: 'nasir_qatami', reciterName: 'Насир аль-Катами'),
    AzanSound(id: 'raad_kurdi', reciterName: 'Раад Мухаммад аль-Курди'),
    AzanSound(
      id: 'ahmed_al_nufais_2',
      reciterName: 'Ахмед аль-Нуфайс',
      note: 'студийная запись',
    ),
    AzanSound(id: 'saidmuhammed', reciterName: 'Саидмухаммед Ныгмат'),
  ];

  static AzanSound byId(String id) => all.firstWhere((s) => s.id == id, orElse: () => all.first);

  /// Путь к аудио для данного чтеца. Пока все указывают на заглушку.
  static String assetFor(String id) => placeholderAsset;
}
