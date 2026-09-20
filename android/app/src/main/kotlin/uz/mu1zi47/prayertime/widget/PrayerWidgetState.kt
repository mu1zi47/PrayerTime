package uz.mu1zi47.prayertime.widget

import android.content.Context
import android.content.res.Configuration
import org.json.JSONObject
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneOffset

/**
 * Everything the widget draws, worked out from the payload the app left
 * behind (see [PrayerWidgetStore]) — no Flutter engine involved.
 *
 * All times are the *selected city's* wall clock, not the device's: the
 * payload carries the city's UTC offset, so a phone travelling with the user
 * keeps showing the schedule of the city they picked, exactly like the app.
 */
sealed interface PrayerWidgetState {

    /**
     * Which of the two themes to paint in. This follows the theme picked
     * *in the app* — the app carries its own Light/Dark/System setting, and
     * a widget that quietly disagreed with it looked like a bug. Only when
     * that setting is "System" does the phone's own dark mode decide.
     */
    val dark: Boolean

    /** Nothing usable stored yet (fresh install, or a schedule that ran out). */
    data class Empty(val message: String, override val dark: Boolean) : PrayerWidgetState

    data class Ready(
        override val dark: Boolean,
        /**
         * Which prayer the button logs, or null when no prayer's window is
         * open — between sunrise and Zuhr there is nothing to mark, so the
         * button is hidden rather than offering to log a Fajr whose time
         * has already run out.
         */
        val currentPrayerKey: String?,
        val currentDateKey: String?,
        val currentMarked: Boolean,
        /**
         * The headline: the prayer that's on now, or "Sunrise" through the
         * stretch after Fajr's window closes.
         */
        val currentName: String,
        /** The one after it, e.g. "Next prayer · Asr 16:57". */
        val nextLabel: String,
        /** Just that next prayer's name, e.g. "Asr". */
        val nextName: String,
        /** And its start, e.g. "16:57". */
        val nextTime: String,
        val markLabel: String,
        /**
         * Millis until the current prayer's window closes — what the
         * Chronometer counts down. That's the next prayer's start, except
         * for Fajr, whose window ends at sunrise; in the stretch between
         * sunrise and Zuhr (no prayer is open) it counts to Zuhr instead.
         */
        val untilWindowEndMillis: Long,
        /**
         * The same moment as an epoch millisecond — when the widget's
         * content actually goes stale. See PrayerWidgetProvider's alarm.
         */
        val nextChangeEpochMillis: Long,
        /**
         * The whole day the current slot belongs to, sunrise included, in
         * order — what the expanded Now Bar lists. Past midnight that's still
         * the day whose Isha is on.
         */
        val today: List<DayEntry>,
    ) : PrayerWidgetState

    data class DayEntry(
        val key: String,
        val name: String,
        val time: String,
        /** The slot that's on now — a prayer, or sunrise until Zuhr. */
        val current: Boolean,
        /** Already started (the current one included). */
        val passed: Boolean,
        /** Logged in the prayer log; always false for sunrise. */
        val marked: Boolean,
    )

    private data class Slot(
        val at: LocalDateTime,
        val key: String,
        val name: String,
        val time: String,
        val dateKey: String,
    ) {
        // Sunrise closes Fajr's window but isn't a prayer of its own — it can
        // never be "the current prayer" or "the next prayer", it only ends one.
        val isPrayer: Boolean get() = key != "sunrise"
    }

    companion object {
        /** "light"/"dark" pin the theme; anything else follows the phone. */
        private fun resolveDark(context: Context, payload: JSONObject?): Boolean =
            when (payload?.optString("theme")) {
                "dark" -> true
                "light" -> false
                else -> (
                    context.resources.configuration.uiMode and
                        Configuration.UI_MODE_NIGHT_MASK
                    ) == Configuration.UI_MODE_NIGHT_YES
            }

        private val ORDER = listOf("fajr", "sunrise", "zuhr", "asr", "maghrib", "isha")

        fun load(context: Context, fallbackMessage: String): PrayerWidgetState {
            val payload = PrayerWidgetStore.payload(context)
            val dark = resolveDark(context, payload)
            if (payload == null) return Empty(fallbackMessage, dark)

            val labels = payload.optJSONObject("labels")
            fun label(key: String, fallback: String) =
                labels?.optString(key)?.takeIf { it.isNotEmpty() } ?: fallback

            val noData = label("noData", fallbackMessage)
            val names = payload.optJSONObject("names") ?: return Empty(noData, dark)
            val days = payload.optJSONArray("days") ?: return Empty(noData, dark)

            val offset = ZoneOffset.ofTotalSeconds(payload.optInt("offsetMinutes") * 60)
            val now = Instant.now().atOffset(offset).toLocalDateTime()

            val slots = mutableListOf<Slot>()
            for (i in 0 until days.length()) {
                val day = days.optJSONObject(i) ?: continue
                val dateKey = day.optString("date").takeIf { it.isNotEmpty() } ?: continue
                val date = try {
                    LocalDate.parse(dateKey)
                } catch (_: Exception) {
                    continue
                }
                val times = day.optJSONObject("times") ?: continue
                for (key in ORDER) {
                    val hhmm = times.optString(key).takeIf { it.isNotEmpty() } ?: continue
                    val at = try {
                        LocalDateTime.of(date, LocalTime.parse(hhmm))
                    } catch (_: Exception) {
                        continue
                    }
                    slots += Slot(at, key, names.optString(key, key), hhmm, dateKey)
                }
            }
            slots.sortBy { it.at }

            // The prayer whose time has most recently arrived — Isha stays
            // "current" past midnight until the next Fajr, which falls out of
            // this naturally since the payload spans whole days either side.
            // The most recent event of any kind — a prayer, or the sunrise
            // that ends Fajr's window. Which of the two it is decides both
            // the headline and whether there's anything to log.
            val lastPassed = slots.lastOrNull { it.at <= now }
            val nextPrayer = slots.firstOrNull { it.at > now && it.isPrayer }
            val nextChange = slots.firstOrNull { it.at > now }
            if (lastPassed == null || nextPrayer == null || nextChange == null) {
                return Empty(noData, dark)
            }

            val openPrayer = lastPassed.takeIf { it.isPrayer }
            val marked = openPrayer != null &&
                PrayerWidgetStore.isMarked(context, openPrayer.dateKey, openPrayer.key)

            val today = slots.filter { it.dateKey == lastPassed.dateKey }.map {
                DayEntry(
                    key = it.key,
                    name = it.name,
                    time = it.time,
                    current = it === lastPassed,
                    passed = it.at <= now,
                    marked = it.isPrayer &&
                        PrayerWidgetStore.isMarked(context, it.dateKey, it.key),
                )
            }

            return Ready(
                dark = dark,
                currentPrayerKey = openPrayer?.key,
                currentDateKey = openPrayer?.dateKey,
                currentMarked = marked,
                currentName = lastPassed.name,
                nextLabel = "${label("next", "")} · ${nextPrayer.name} ${nextPrayer.time}",
                nextName = nextPrayer.name,
                nextTime = nextPrayer.time,
                markLabel = if (marked) label("marked", "") else label("markDone", ""),
                untilWindowEndMillis = Duration.between(now, nextChange.at).toMillis(),
                nextChangeEpochMillis = nextChange.at.toInstant(offset).toEpochMilli(),
                today = today,
            )
        }
    }
}
