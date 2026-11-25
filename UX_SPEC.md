# Prayer Times App — UX Specification

> **Version:** 0.3 — agreed working UX baseline  
> **Audience:** Flutter developers, AI coding agents, QA  
> **Scope:** redesign of **existing** functionality; no new social features  
> **Companion:** [`README.md`](./README.md) — authoritative design-system/UI Kit specification  
> **Language:** Russian for product UI examples; localization-ready architecture

## 0. READ FIRST — implementation contract

1. Read **both** `README.md` and `UX_SPEC.md` before editing production screens. `README.md` owns visual tokens; this file owns behavior and information architecture.
2. Implement the **existing** prayer-times app first. **Do not implement** friends, social reminders, public prayer history, streaks, achievements, or a Qibla compass as part of this redesign.
3. **Remove the persistent bottom tab navigation** in the proposed UX; the home screen becomes the main entry point. Preserve platform back gestures and route history.
4. Never replace existing working prayer calculations, localization, notifications, calendar history, mosque data or persistence with demo data. Inspect the current code and integrate with existing services.
5. All sample times, dates, completion states, and names in this file are **illustrative**. Obtain production values from app state.
6. Do not treat visual mockup illustrations as authoritative when they contradict this specification. In particular: **no notification bell**, **no large date header**, **no “Mark all” action**, **no decorative mosque illustration** in the next-prayer block.
7. No new functionality or irreversible data migrations without product-owner approval. Unspecified behavior belongs in `OPEN_DECISIONS.md` (or an issue), not in invented implementation.

## 1. Product objective

The app serves two frequent intents:

- **Prayer check-in:** open app → see next prayer/countdown and today's times → tap a prayer → mark it.
- **Tool launch:** open app → immediately launch a frequently used tool (e.g., mosque map) without navigating through tabs.

The home page is a **functional launch point**, not a generic dashboard or social feed. Keep content compact, scannable, and accessible. A user may rely on widgets and open the app only to use a particular tool.

## 2. Approved information architecture

```text
Home (single primary entry point; no bottom navigation)
├── City selector (tap city label)
├── Settings (top-right icon)
│   ├── Prayer-time settings
│   │   ├── City
│   │   ├── Calculation method
│   │   ├── Asr madhhab calculation
│   │   └── Show Tahajjud option
│   ├── System settings
│   │   ├── Prayer notifications (per prayer)
│   │   ├── Notification sound
│   │   ├── Now Bar (if supported in current build)
│   │   ├── Reminder before prayer period ends
│   │   └── Language and other existing settings
│   └── Existing feedback links
├── Next prayer summary (information)
├── Quick access (exactly 3 user-customizable slots)
│   ├── Tap slot → launch its tool
│   ├── "Все" → All tools catalog
│   └── Configure via catalog → Quick access editor
├── Today's schedule (5 prayers + sunrise)
│   ├── Tap prayer → prayer mark bottom sheet
│   └── "На месяц" → Monthly prayer timetable
└── All tools catalog
    ├── Monthly prayer timetable
    ├── Mosque map
    ├── Prayer calendar/history
    ├── 99 names of Allah (favorites, search)
    ├── Tasbih
    └── Quick access editor
```

**Qibla:** future tool, **not implemented**. Do not create a fake functional route. Optionally describe it as “Скоро” in planning material, but do not place it in a tappable quick-access slot until built. Other future features must not appear as functional controls.

**Settings:** reached from the home top-right settings icon; it does **not** occupy a permanent bottom tab. Existing settings subpages and bottom sheets retain their real behavior unless explicitly redesigned later.

## 3. Home screen — approved order and behavior

### 3.1 Vertical order

1. **Compact top row:** tappable city label with dropdown indicator (e.g. `Ташкент`), settings icon on right. Touch targets >= 48 dp.
2. **Next prayer:** label (`Следующий намаз`), contextual day indicator (`Сегодня`/`Завтра` where necessary), prayer name, start time and remaining time. Show accurate day rollover after Isha. Do not show a redundant large weekday/date heading above it.
3. **Quick access heading:** `Быстрый доступ` and action `Все` that opens the tools catalog.
4. **Exactly three quick-action slots:** each icon + readable label; all slots user-replaceable. Initial proposed defaults: `Карта мечетей`, `Календарь намазов`, `Имена Аллаха`. Defaults are provisional and may be changed by product owner.
5. **Schedule heading:** `Расписание сегодня` and right-aligned action `На месяц` opening the existing monthly timetable. This **replaces** the earlier suggested `Отметить все` button.
6. **Today's schedule:** `Фаджр`, `Восход`, `Зухр`, `Аср`, `Магриб`, `Иша` in chronological order; show each start time and its appropriate state.

### 3.2 Explicit removals

- No large `Воскресенье / 15 ноября` header at the top.
- No notification bell in the home header. Notification configuration stays under Settings.
- No `Отметить все` button on home.
- No persistent bottom navigation.
- No forced decorative imagery, gradients/glassmorphism or mosque silhouette; follow the restrained UI Kit.
- No extra duplicate daily-progress card: statuses already appear in the schedule.

### 3.3 Layout and scrolling

- One main vertical scroll region; no nested scrolling schedule within the page.
- The first viewport should prioritize **city, next prayer, quick actions**, with the schedule beginning as early as practical.
- Avoid fixed heights that clip localized names or enlarged system text. Use the spacing, radius, typography and width rules from `README.md`.
- Keep next-prayer presentation compact; don't consume half the screen with a hero card.
- No floating bottom control obscuring the final schedule row; use SafeArea and account for system navigation insets.
- The schedule may extend below the fold on smaller phones; scrolling must remain predictable.
- Do **not** introduce a new sticky tab strip when scrolling. This was rejected as an unnecessary substitute for bottom navigation.

### 3.4 Prayer-time semantics

- Distinguish the **next prayer** (temporal state) from the **user's prayer mark** (completion state); these are independent.
- `Восход` is **informational**: show time but **do not** allow marking it as one of the five daily prayers.
- Never assume “no mark” means a prayer was missed. Label it `Нет отметки` if a textual label is needed.
- Don't infer whether a prayer was on time from the clock alone: use the saved user mark and existing app rules.
- For date rollover, the next prayer may belong to tomorrow even while today's schedule remains visible.

## 4. Prayer mark — bottom sheet interaction

**Entry:** tap any of the five prayer rows on Home; existing calendar prayer rows may reuse the same component.

**Title:** `Как прошёл {название намаза}?`  
**Supporting text:** `Отметьте, как вы совершили этот намаз`.

Actions:

1. `Прочитал вовремя` → save `on_time`.
2. `Прочитал с опозданием` → save `late`.
3. `Убрать отметку` → clear saved mark. **Show only if a mark exists**.

**After successful action:** persist through the existing repository/storage layer; dismiss bottom sheet; immediately update the corresponding schedule row and calendar history. If saving fails, show an understandable error and retain/revert UI state consistently (do not claim success).

**State presentation in list:**

| Stored state | Meaning | Suggested indicator |
|---|---|---|
| `on_time` | User marked prayer on time | Check-circle + optional `Прочитан вовремя` |
| `late` | User marked prayer late | Clock + optional `Прочитан с опозданием` |
| `unmarked` | No user mark saved | Neutral outline circle + `Нет отметки` when needed |
| `sunrise` | Informational event, not a prayer mark | Sunrise icon, no mark sheet |

Icons and accessible labels carry meaning; color is secondary. Use the approved accent palette (do not invent bright success colors outside tokens). A mark can be changed by opening the sheet again. Respect the existing domain model and date boundaries.

**Not specified yet:** whether future prayers may be marked, any validation/cutoff rule, and any confirmation before clearing a mark. Preserve existing behavior unless explicitly approved otherwise.

## 5. Quick access — exactly three replaceable tools

- Show **three slots** on home at all times, not an unbounded set of tiles.
- Tap a slot to open the selected, implemented tool directly.
- Tap `Все` in the `Быстрый доступ` heading to open `Все инструменты`.
- Quick-access customization is **discoverable in the catalog** via a clearly labeled `Настроить` control. Long-press on a slot can be considered later, but is **not required** for v0.3.
- Editor displays current three selections, lets user **replace and reorder** them, and saves changes only after pressing `Сохранить`.
- Prevent duplicate tools in the three slots. A selection already in another slot should be disabled or handled by an explicit swap (choose one implementation and document it).
- Persist selections and order locally using the project's existing preferences mechanism. Validate saved tool IDs when available tools change after app updates; fall back safely.
- A future/unimplemented tool (Qibla) cannot be selected. Avoid fake navigation or dead buttons.

### Quick-access editor flow

```text
Home → Все → All tools → Настроить
  → choose/replace three slots
  → reorder if desired
  → Сохранить
  → return to catalog (or previous screen)
  → Home shows new choices
```

Use accessible explicit reorder controls or a reorderable list with screen-reader support. Unsaved edits should not silently overwrite saved settings; decide how to handle leaving with unsaved changes during implementation review.

## 6. All tools catalog

**Entry:** `Все` next to `Быстрый доступ` on Home. **Presentation:** full page with back navigation, not a modal overlay.

**Initial content:**

- **Основные:** `Расписание на месяц`, `Карта мечетей`, `Календарь намазов`.
- **Духовные инструменты:** `99 имён Аллаха`, `Тасбих`.
- **Configuration:** `Настроить быстрый доступ` is prominent near the top.

Use compact, readable **rows with separators** rather than a wall of large cards. Group labels should remain clear. Do not show an inoperative Qibla item as an active route. A disabled `Скоро` label is optional and should be approved before release.

**Search:** not required while catalog contains only ~5 tools; add when the catalog genuinely grows. Keep future feature architecture extensible without adding placeholders to production UI.

**Back behavior:** if a tool is launched from Home shortcut, Back returns to Home; if launched from catalog, Back returns to catalog. Use the real navigation stack, not a hardcoded `goHome()` for every tool.

## 7. Existing screens — preserve during the redesign

These screens exist in the screenshots and must remain reachable even if their **internal redesign is deferred**:

| Screen | Existing behaviors to retain | Access in proposed UX |
|---|---|---|
| Monthly timetable | View prayer times across month | `На месяц` beside schedule heading; catalog |
| Prayer calendar | Select day, view/edit prayer marks and history | Shortcut or catalog |
| Mosque map | View map of mosques | Shortcut or catalog |
| 99 names of Allah | Names, Arabic text, favorites, search | Shortcut or catalog |
| Tasbih | Existing tasbih functionality | Shortcut or catalog |
| Settings | Prayer time and system settings, feedback | Top-right settings icon |
| Prayer-time settings | City, method, Asr calculation, Tahajjud toggle | Settings |
| City selection | Automatic detection, city list, search | City header; settings |
| Notification settings | Per-prayer modes; end-of-period reminders | System settings |
| Calculation method selection | Select method | Prayer-time settings |

**Important:** these are navigation/integration requirements, **not approval** to redesign all secondary screens based on the latest image. Their detailed UX should be reviewed screen by screen.

## 8. UX flows and acceptance criteria

### Flow A — check next prayer

1. Open app (including after returning from background).
2. See selected city and next prayer with its start time.
3. See countdown based on the current clock and correct time zone.
4. After the final prayer of the day, see `Завтра` for the next day's Fajr.

**Accept:** countdown updates without manually refreshing; day rollover correct; no hardcoded times; offline behavior follows existing data availability.

### Flow B — mark prayer

1. Open Home.
2. Tap `Магриб` row.
3. Bottom sheet appears with two mark choices and conditional clear choice.
4. Select a state.
5. Sheet closes after successful persistence; Home and calendar agree.

**Accept:** tapping Sunrise never opens the mark sheet; no mark is not shown as missed; errors are handled.

### Flow C — open mosque map quickly

1. Open Home.
2. Tap `Мечети` if selected as one of three shortcuts.
3. Mosque map opens directly.
4. Back returns to Home.

**Accept:** no mandatory detour through `Ещё` or bottom tabs.

### Flow D — customize quick actions

1. Home → `Все` → `Настроить`.
2. Replace `Имена Аллаха` with `Тасбих`.
3. Reorder three selected tools.
4. Save.
5. Return Home; updated order persists after restart.

**Accept:** exactly 3 unique implemented tools; cancel does not silently save; invalid persisted IDs handled.

### Flow E — reach a non-shortcut tool

1. Home → `Все`.
2. Select `Тасбих`.
3. Back returns to `Все инструменты`; another Back returns Home.

**Accept:** predictable stack; Android system back gesture works.

### Flow F — change calculation settings

1. Home → settings icon → `Время намаза`.
2. Select method or city using existing controls.
3. Save/update through existing app services.
4. Return Home; times reflect the selected configuration.

**Accept:** redesign does not break prayer calculation behavior or existing settings.

## 9. UI composition rules inherited from README

- Balanced geometry: use the radius/spacing tokens in `README.md`, not arbitrary pill shapes.
- Flat dark navy surfaces, warm gold accent, restrained separators; no gratuitous shadows, glows, or heavy gradients.
- Prioritize text hierarchy and tabular prayer times; avoid repeated decorative icons.
- Rows must be comfortably tappable; icon-only controls need meaningful semantic labels and minimum touch targets.
- Support small phones, larger text, Arabic RTL segments, localization and safe areas.
- Animate state changes subtly; no staggered entrance animations on every app launch.
- A reference image is **not** permission to add unsupported features or decoration.

## 10. Suggested Flutter implementation boundaries

```text
lib/
  core/design_system/        # governed by README.md
  features/home/
    presentation/home_screen.dart
    presentation/widgets/next_prayer_summary.dart
    presentation/widgets/quick_access_strip.dart
    presentation/widgets/today_prayer_list.dart
  features/tools/
    domain/tool_definition.dart
    presentation/all_tools_screen.dart
    presentation/quick_access_editor_screen.dart
    data/quick_access_preferences.dart
  features/prayer_marks/
    presentation/prayer_mark_sheet.dart
    # reuse existing domain/repository if present
  features/settings/         # existing feature; integrate, don't rewrite blindly
  features/prayer_times/     # existing calculations; integrate
```

This is a **suggested** organization, not a mandate to duplicate existing classes. Inspect the current project first and adapt naming to its architecture. Keep UI components independent of prayer calculation and storage code.

## 11. Implementation order for an AI agent

1. Audit the existing Flutter app: routes, models, storage, calculations, notification logic, existing pages, tests. **Do not delete functionality.**
2. Read and implement the approved design tokens/components from `README.md` as needed.
3. Implement home composition with real data, correct next-prayer/day logic, and schedule marks.
4. Integrate existing prayer mark bottom sheet or refactor it without changing saved semantics.
5. Implement tools catalog and real route links to existing screens.
6. Implement three-slot editor, persistence, validation and reorder behavior.
7. Replace old bottom-tab entry points with the new route structure; test Android back and deep links if any.
8. Test accessibility, scaling, small screens, persistence, navigation, calendar consistency, and time rollover.
9. Only then consider detailed redesign of secondary screens in separate approved specs.

## 12. Explicit open decisions — do not guess

- Whether the initial 3 shortcuts should be `Мечети / Календарь / Имена Аллаха` or another default set.
- How exactly reordering and duplicate-selection resolution work in the editor (choose and confirm during implementation).
- Whether leaving the editor with unsaved changes prompts for confirmation.
- Whether any contextual date belongs **inside** the next-prayer summary (large date header is definitively removed).
- Whether to show a textual mark subtitle on every prayer row or only when a mark exists, especially on compact screens.
- Rules for marking future prayers, cutoff times and undo confirmation: retain existing behavior until reviewed.
- Detailed layout/UX for secondary screens, including mosque map, calendar, monthly timetable, notifications, names, and tasbih.
- Whether future Qibla is listed disabled as `Скоро` or completely hidden until launch.

## 13. Definition of done

- [ ] Home has no large date header, bell, Mark All, or bottom tabs.
- [ ] City selector and settings are accessible from the compact header.
- [ ] Next prayer and countdown are correct with today/tomorrow context.
- [ ] Three customizable shortcut slots open real implemented tools.
- [ ] `Все` opens catalog; `На месяц` opens monthly timetable.
- [ ] Five prayers are markable via bottom sheet; sunrise is not.
- [ ] `on_time`, `late`, `unmarked` states persist and synchronize with calendar.
- [ ] Quick-access selection/order persists and prevents duplicates.
- [ ] All existing features remain reachable.
- [ ] Back navigation, safe areas, screen readers, localization and large text work.
- [ ] No demo data, fake Qibla screen or unsupported new features are shipped.

---

**Handoff prompt for AI developer:**

> Read `README.md` and `UX_SPEC.md` completely. First audit the existing Flutter project and list what is already implemented. Follow the approved design tokens and the home/catalog/prayer-mark UX. Preserve existing data and feature behavior. Do not invent missing product decisions; list them explicitly. Propose a file-by-file implementation plan, then implement incrementally with tests. Do not add friends, streaks, Qibla, a bottom navigation bar, a notification bell, a large date header, or a Mark All button.
