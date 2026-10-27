<div align="center">

<img src="docs/assets/banner.png" alt="MindDrop" width="100%">

**Catch every thought before it slips away.**

A fast, offline, beautifully themed task inbox for Android — built for the moment
something pops into your head.

[![CI](https://github.com/amirh3347/MindDrop/actions/workflows/ci.yml/badge.svg)](https://github.com/amirh3347/MindDrop/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/amirh3347/MindDrop?sort=semver)](https://github.com/amirh3347/MindDrop/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-7C5CFF.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Android%207%2B-22D3EE.svg)

[**Download the latest APK**](https://github.com/amirh3347/MindDrop/releases/latest) ·
[فارسی](README.fa.md) ·
[Building](docs/BUILDING.md) ·
[Changelog](CHANGELOG.md)

</div>

---

## Why MindDrop?

Most to-do apps want you to plan. MindDrop is for the other moment: you're walking,
cooking, half-asleep — and you remember something you need to do later. Open the app,
type a line, hit enter. Done in two seconds. Sort it out later.

## Features

| | |
|---|---|
| ⚡ **Quick capture** | One tap, one line, enter. Type `#tags`, `!` / `!!` / `!!!` for priority and `today` / `tomorrow` (or `امروز` / `فردا`) — they are detected as you type. "Save & add another" lets you dump several thoughts in a row. |
| 🗂️ **Smart views** | **All** (pinned · overdue · today · upcoming · no date), **Today**, **Upcoming** (grouped by day) and **Done** (grouped by completion day). Filter by tag in one tap. |
| ✍️ **Rich tasks** | Notes, priority, due date and time, reminder, tags, subtasks with progress, pinning. Everything saves automatically. |
| 🔔 **Reminders** | Exact-time notifications that survive reboots. Tap one to jump straight into the task. |
| 🔍 **Instant search** | Searches titles, notes, subtasks and tags as you type, with status, priority and tag filters. Forgiving with Persian/Arabic letter variants (ي/ی, ك/ک), half-spaces and Persian digits. |
| 👆 **Gestures** | Swipe toward the end to complete, toward the start to delete — always with **undo**. Long-press for pin / duplicate / delete. |
| 🎨 **Themes** | Dark by default, light, or follow the system. Pure-black AMOLED mode and 8 accent colors, with smooth animated theme changes. |
| 🌐 **Persian & English** | Full right-to-left layout, Persian digits and the Solar Hijri (Jalali) calendar — or Gregorian, your choice. Language and theme are picked on first launch. |
| 💾 **Backup & move phones** | Export everything to a single JSON file (save it, or share to Telegram / Drive / email) and import it on another phone — merge or replace. |
| 📤 **Share to MindDrop** | Share text or a link from any app and it becomes a task. |
| 🚀 **Launcher shortcuts** | Long-press the app icon for *New drop* and *Search*. |
| 📊 **Statistics** | Open / completed / overdue counts, daily streak 🔥, last 7 days chart and top tags. |
| 🔒 **Private** | No account, no ads, no tracking, no internet permission. Your tasks never leave your phone unless you export them. |

## Install

1. Open the [latest release](https://github.com/amirh3347/MindDrop/releases/latest) on your phone.
2. Download `MindDrop-vX.Y.Z.apk` and open it.
3. If Android asks, allow installing apps from your browser / file manager.

Requires **Android 7.0** or newer. New versions install over the old one and keep your data.

## Quick capture cheat sheet

| You type | You get |
|---|---|
| `Buy milk tomorrow #home` | "Buy milk", due tomorrow, tag `home` |
| `Call the bank !!!` | "Call the bank", high priority |
| `خرید نان فردا #خانه !!` | «خرید نان»، فردا، برچسب `خانه`، اولویت متوسط |
| `Idea for the blog #ideas` | "Idea for the blog", tag `ideas` |

Detected parts appear as chips under the text field — tap ✕ on a chip to undo the
detection. Smart capture can be turned off in **Settings → Behavior**.

## Moving to a new phone

1. Old phone: **Settings → Backup & data → Export to file** (or **Share backup** to send it
   to yourself on Telegram, Drive, email…).
2. New phone: install MindDrop, then **Settings → Backup & data → Import from file**.
3. Choose **Merge** (keep what's there, add the rest) or **Replace** (start fresh from the
   backup).

The file format is plain, documented JSON — see [docs/BACKUP_FORMAT.md](docs/BACKUP_FORMAT.md).

## Building

You don't need anything installed locally. **GitHub Actions builds the APK for you:**

- every push to `main` → a test build attached to the workflow run (Actions tab → run →
  *Artifacts*);
- every tag `vX.Y.Z` → a signed APK published on the Releases page.

One-time setup (a signing key, so updates install over each other) and local development
instructions are in **[docs/BUILDING.md](docs/BUILDING.md)**.

```bash
# Release a new version
git tag v1.0.0
git push origin v1.0.0
```

## Tech

- [Flutter](https://flutter.dev) (Material 3) — single codebase, 60/120 fps UI
- [provider](https://pub.dev/packages/provider) for state,
  a single atomically-written JSON file for storage,
  [shared_preferences](https://pub.dev/packages/shared_preferences) for settings
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) for reminders
- A small Kotlin bridge (`MainActivity.kt`) for share-to-app, launcher shortcuts and
  file save/open through the system picker — no extra plugins
- Hand-written Jalali calendar conversion and date picker
- [Vazirmatn](https://github.com/rastikerdar/vazirmatn) font

Architecture notes: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Project structure

```
lib/
  core/       calendar, localization, theme, quick-capture parser, platform bridge
  data/       task store, repository (JSON file), queries & stats, backup, settings
  models/     Task and Subtask
  services/   reminder notifications
  ui/         screens and widgets
android/      Android host app (manifest, Kotlin bridge, icons, shortcuts)
assets/       fonts and logo sources
test/         unit and widget tests
docs/         documentation
```

## Contributing

Bug reports, ideas and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE). The Vazirmatn font is licensed under the
[SIL Open Font License 1.1](assets/fonts/OFL.txt).
