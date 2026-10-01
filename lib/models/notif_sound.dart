import '../l10n/app_localizations.dart';

/// A notification sound as it was picked: one of the phone's sounds (see
/// NotificationSoundsBridge), kept with the name it was listed under so
/// settings can show it without asking the phone again — or, with no
/// [uri], whatever the phone's default notification sound is.
class NotifSound {
  final String? uri;
  final String? title;

  const NotifSound({required this.uri, required this.title});

  const NotifSound.phoneDefault() : uri = null, title = null;

  bool get isDefault => uri == null;

  String label(AppLocalizations t) =>
      isDefault ? t.soundDefault : (title ?? t.soundDefault);

  Map<String, Object?> toJson() => {'uri': uri, 'title': title};

  static NotifSound fromJson(Object? json) {
    if (json is! Map) return const NotifSound.phoneDefault();
    final uri = json['uri'];
    final title = json['title'];
    return uri is String
        ? NotifSound(uri: uri, title: title is String ? title : null)
        : const NotifSound.phoneDefault();
  }

  @override
  bool operator ==(Object other) => other is NotifSound && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}
