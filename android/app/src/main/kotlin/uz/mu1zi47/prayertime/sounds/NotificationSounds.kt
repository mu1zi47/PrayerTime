package uz.mu1zi47.prayertime.sounds

import android.content.Context
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.provider.Settings

/**
 * The phone's own sounds, for picking a prayer notification's sound — see
 * NotificationSoundsBridge on the Dart side. Lists them, and plays one at a
 * time so a choice can be heard before it's made.
 */
object NotificationSounds {
    private var playing: Ringtone? = null

    /**
     * Every notification, ringtone and alarm sound the phone has, in that
     * order and each group as the system sorts it. A sound listed under more
     * than one type shows up only the first time — Samsung marks its
     * ringtones as alarms too, so ringtones come first and the alarms
     * section keeps just the alarms.
     */
    fun list(context: Context): List<Map<String, String>> {
        val result = mutableListOf<Map<String, String>>()
        val seen = HashSet<String>()
        val types = listOf(
            RingtoneManager.TYPE_NOTIFICATION to "notification",
            RingtoneManager.TYPE_RINGTONE to "ringtone",
            RingtoneManager.TYPE_ALARM to "alarm",
        )
        for ((type, kind) in types) {
            val manager = RingtoneManager(context).apply { setType(type) }
            try {
                val cursor = manager.cursor
                try {
                    while (cursor.moveToNext()) {
                        val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                            ?: continue
                        val uri = manager.getRingtoneUri(cursor.position)?.toString()
                            ?: continue
                        if (seen.add(uri)) {
                            result.add(mapOf("title" to title, "uri" to uri, "kind" to kind))
                        }
                    }
                } finally {
                    cursor.close()
                }
            } catch (_: Exception) {
                // A type the phone can't list (no media provider for it,
                // say) is just left out.
            }
        }
        return result
    }

    /** The name of the sound "default" currently stands for on this phone. */
    fun defaultTitle(context: Context): String? = try {
        val actual = RingtoneManager.getActualDefaultRingtoneUri(
            context,
            RingtoneManager.TYPE_NOTIFICATION,
        )
        actual?.let { RingtoneManager.getRingtone(context, it)?.getTitle(context) }
    } catch (_: Exception) {
        null
    }

    /** Plays [uri] — the phone's default sound when null — stopping any other. */
    fun play(context: Context, uri: String?) {
        stop()
        val target = if (uri == null) Settings.System.DEFAULT_NOTIFICATION_URI else Uri.parse(uri)
        val ringtone = try {
            RingtoneManager.getRingtone(context, target)
        } catch (_: Exception) {
            null
        } ?: return
        // Played the way the notification itself would be, so the preview
        // follows the same volume.
        ringtone.audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        ringtone.play()
        playing = ringtone
    }

    fun stop() {
        playing?.stop()
        playing = null
    }
}
