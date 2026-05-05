# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run app (debug, device/emulator required)
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

> `test/widget_test.dart` is a placeholder smoke test — the actual `pumpWidget` call is commented out. No meaningful tests exist yet.

## Architecture

Flutter 3 app targeting Android. Fully offline — all data stays in SQLite on-device. UI is in Spanish.

### State management

A single `AppProvider` (`lib/providers/app_provider.dart`) holds all app state as a `ChangeNotifier`. It is the only provider, injected at the root in `main.dart`. Every screen reads/writes via `context.watch<AppProvider>()` / `context.read<AppProvider>()`.

### Data layer

`DatabaseHelper` (`lib/services/database_helper.dart`) is a singleton wrapping `sqflite`. Database file: `fittracker.db`, current version: **6**. Schema migrations are handled manually in `_upgradeDB` — always wrap each `ALTER TABLE` in a `try/catch` and increment the version.

All models live in `lib/models/models.dart` and follow a consistent `toMap()` / `fromMap()` pattern for SQLite serialization. IDs are UUIDs generated client-side.

**Models:** `Routine`, `Exercise`, `WorkoutLog`, `WeightEntry`, `Meal`, `MealItem`, `ShoppingItem`, `WaterLog`, `MedicalReminder`, `ProgressPhoto`, `BodyMeasurement`, `UserProfile`

**DB tables:** `routines`, `exercises`, `workout_logs`, `workout_sets`, `weight_entries`, `meals`, `meal_items`, `shopping_list`, `water_log`, `medical_reminders`, `medical_logs`, `progress_photos`, `body_measurements`, `profile`

`AppProvider.init()` loads everything from SQLite on startup and calls `_autoBackupIfNeeded()` (exports JSON to SharedPreferences if last backup > 7 days ago). Mutations go through `AppProvider` methods that update both the in-memory list and the database, then call `notifyListeners()`.

User preferences (theme, onboarding flag, water goal) are stored in `shared_preferences`, not SQLite.

`UserProfile` exposes `dailyCalorieGoal(weight)` (Harris-Benedict + activity factor) and `dailyProteinGoal(weight)` — both are overridable via `customCalorieGoal` / `customProteinGoal` fields added in migration v6.

### Navigation

`MainNavigation` in `main.dart` uses `IndexedStack` + `NavigationBar` with 6 tabs: Home, Rutinas, Peso, Dieta, Alarmas, Ajustes. Before reaching `MainNavigation`, `OnboardingScreen` is shown on first launch (guarded by the `onboardingDone` flag in `AppProvider`). On `initState`, `MainNavigation` checks notification and exact-alarm permissions and shows dialogs if missing.

### Diet / food search

`lib/screens/diet/` includes a food search screen that makes HTTP requests (`http` package) to an external food API. This is the only screen that requires internet access.

### Notifications

`NotificationService` (`lib/services/notification_service.dart`) is a singleton initialized before `runApp`. It uses `flutter_local_notifications` with timezone hardcoded to `Europe/Madrid`. On Android 12+, exact alarms require the `SCHEDULE_EXACT_ALARM` permission. With permission it uses `AndroidScheduleMode.alarmClock`; without, it falls back to `AndroidScheduleMode.inexactAllowWhileIdle`.

`scheduleReminder()` dispatches to `scheduleDaily()` or `scheduleWeekly()` based on frequency: `daily`, `weekdays`, `weekends`, `weekly`, `custom`.

### Native Android bridge

`MainActivity.kt` exposes three methods over `MethodChannel('com.example.fittracker/permissions')`:
- `canScheduleExactAlarms` — returns whether exact alarms are permitted
- `openExactAlarmSettings` — opens system exact-alarm settings
- `openBatterySettings` — opens battery optimization exemption

> **Note:** Flutter-side code references the channel as `fittracker/permissions`; the Kotlin side registers it as `com.example.fittracker/permissions`. Verify both match if the native bridge appears broken.

### Screens

| Screen | Path |
|---|---|
| Dashboard | `lib/screens/home/home_screen.dart` |
| Routines + active workout | `lib/screens/routines/` |
| Weight + charts (`fl_chart`) | `lib/screens/weight/weight_screen.dart` |
| Diet + food search | `lib/screens/diet/` |
| Reminders/alarms | `lib/screens/reminders/reminders_screen.dart` |
| Medical | `lib/screens/medical/medical_screen.dart` |
| Settings + progress photos | `lib/screens/settings/settings_screen.dart` |
| Progress photos | `lib/screens/progress/progress_screen.dart` |
| Import/Export | `lib/screens/import/import_screen.dart` |
| Onboarding | `lib/screens/onboarding/onboarding_screen.dart` |

`lib/reminders/reminders_screen.dart` is a duplicate — canonical file is under `lib/screens/reminders/`.
