# Architecture

MindDrop is a small Flutter app with deliberately few dependencies.

```
┌──────────────── UI (lib/ui) ─────────────────┐
│ HomeScreen · QuickAddSheet · TaskEditor ·    │
│ SearchScreen · SettingsScreen · Stats ·      │
│ Onboarding                                    │
└──────────────┬───────────────────────────────┘
               │ context.watch / read (provider)
┌──────────────▼──────────────┐   ┌──────────────────────┐
│ TaskStore (ChangeNotifier)  │──▶│ ReminderScheduler     │
│  in-memory list, mutations, │   │ (NotificationService) │
│  undo, import               │   └──────────────────────┘
└──────────────┬──────────────┘
               │ save(list) — serialized, atomic
┌──────────────▼──────────────┐   ┌──────────────────────┐
│ FileTaskRepository          │   │ SettingsStore         │
│  tasks.json (+ .bak)        │   │ shared_preferences    │
└─────────────────────────────┘   └──────────────────────┘
```

## Data flow

- **`TaskStore`** is the single source of truth. Every mutation updates the in-memory
  list, calls `notifyListeners()` immediately (so the UI never waits on disk) and then
  persists in the background.
- **`FileTaskRepository`** writes the whole list as one JSON document. Writes are queued so
  they never interleave, go to `tasks.json.tmp` first and are then renamed over
  `tasks.json`, so a crash can't corrupt the file. The previous version is kept as
  `tasks.json.bak` and used automatically if the main file is unreadable. For a personal
  task list (thousands of items at most) this is simpler and more robust than a database.
- **Queries** (`data/task_query.dart`) are pure functions: sections for each view, search,
  statistics. They're easy to unit-test and fast enough to run on every rebuild.
- **Backups** use exactly the storage format (`data/backup.dart`), see
  [BACKUP_FORMAT.md](BACKUP_FORMAT.md).

## Platform bridge

`android/app/src/main/kotlin/com/minddrop/app/MainActivity.kt` exposes a method channel
`minddrop/platform` (Dart side: `core/platform_bridge.dart`):

| Method | Purpose |
|---|---|
| `takeLaunchAction` | Text shared from another app (`ACTION_SEND`) or a launcher shortcut that started the app |
| `onAction` (native → Dart) | Same, while the app is already running |
| `saveFile` / `openFile` | Storage Access Framework pickers for export / import |
| `shareFile` | Shares a backup through `FileProvider` + the system share sheet |
| `getTimeZone`, `getAppVersion` | Device time zone for reminders, app version for *About* |

Doing this natively avoids four extra plugins and their Gradle/Kotlin version churn.

## Localization

`core/l10n.dart` holds Persian and English strings in two maps with English fallback; a
test ensures both define the same keys. Material widgets are localized through
`flutter_localizations`, which also flips the layout to right-to-left for Persian.

Dates go through `AppCalendar` (`core/calendar.dart`), which formats in Jalali or Gregorian
and converts digits. The Jalali conversion is a well-known arithmetic algorithm, verified
by a round-trip test over 12 years of days.

## Reminders

`services/notification_service.dart` wraps `flutter_local_notifications`. Each task maps to
a stable notification id (FNV-1a hash of its id). Reminders are scheduled with exact
alarms (`USE_EXACT_ALARM` on Android 13+, `SCHEDULE_EXACT_ALARM` on 12) and fall back to
inexact alarms if the OS refuses. The plugin's boot receiver restores them after a reboot,
and the app re-syncs all reminders on start-up and after imports.

## Theming

`core/theme.dart` builds Material 3 themes from the selected accent with
`ColorScheme.fromSeed`, then overrides the surface colors with the ink-blue palette from
the logo (or pure black in AMOLED mode). The logo itself is drawn with a `CustomPainter`
(`ui/widgets/logo.dart`) from the same geometry as `assets/branding/logo.svg`.
