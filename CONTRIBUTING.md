# Contributing to MindDrop

Thanks for helping! Bug reports, translations, ideas and pull requests are all welcome.

## Reporting bugs and ideas

Use the issue templates. For bugs, include your Android version, phone model, MindDrop
version (Settings → About) and steps to reproduce.

## Development setup

You need the Flutter stable SDK (see `FLUTTER_VERSION` in `.github/workflows/ci.yml`),
the Android SDK and JDK 17. Details in [docs/BUILDING.md](docs/BUILDING.md).

```bash
flutter pub get
flutter run
```

No local setup? Open a pull request anyway: CI analyzes, tests and builds an APK you can
download from the workflow run.

## Before opening a pull request

```bash
dart format lib test
flutter analyze
flutter test
```

- Keep pull requests focused; one feature or fix per PR.
- Add or update tests for logic in `lib/core` and `lib/data`.
- New user-facing strings go into **both** maps in `lib/core/l10n.dart`
  (`test/l10n_test.dart` checks this).
- Check the UI in both Persian (right-to-left) and English, and in dark and light themes.
- Add a line under `## [Unreleased]` in `CHANGELOG.md`.

## Project layout

See the *Project structure* section of the [README](README.md) and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Commit messages

Short imperative subject (`Add snooze to reminders`), optional body explaining *why*.
