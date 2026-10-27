import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalendarSystem { jalali, gregorian }

/// User preferences, persisted with shared_preferences.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs) {
    _onboarded = _prefs.getBool(_kOnboarded) ?? false;
    _language = _prefs.getString(_kLanguage);
    _themeMode = _parseThemeMode(_prefs.getString(_kTheme));
    _amoled = _prefs.getBool(_kAmoled) ?? false;
    _accentIndex = _prefs.getInt(_kAccent) ?? 0;
    final cal = _prefs.getString(_kCalendar);
    _calendar = cal == null ? null : CalendarSystem.values.asNameMap()[cal];
    _showCompletedInInbox = _prefs.getBool(_kShowCompleted) ?? false;
    _smartParse = _prefs.getBool(_kSmartParse) ?? true;
    _haptics = _prefs.getBool(_kHaptics) ?? true;
    _reminderHour = _prefs.getInt(_kReminderHour) ?? 9;
  }

  static Future<SettingsStore> create() async =>
      SettingsStore(await SharedPreferences.getInstance());

  static const _kOnboarded = 'onboarded';
  static const _kLanguage = 'language';
  static const _kTheme = 'themeMode';
  static const _kAmoled = 'amoled';
  static const _kAccent = 'accent';
  static const _kCalendar = 'calendar';
  static const _kShowCompleted = 'showCompletedInInbox';
  static const _kSmartParse = 'smartParse';
  static const _kHaptics = 'haptics';
  static const _kReminderHour = 'reminderHour';

  final SharedPreferences _prefs;

  late bool _onboarded;
  String? _language;
  late ThemeMode _themeMode;
  late bool _amoled;
  late int _accentIndex;
  CalendarSystem? _calendar;
  late bool _showCompletedInInbox;
  late bool _smartParse;
  late bool _haptics;
  late int _reminderHour;

  static ThemeMode _parseThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark, // MindDrop is dark by default
      };

  bool get onboarded => _onboarded;

  /// `fa` or `en`. Before the user picks one, guessed from the device.
  String get language =>
      _language ?? (PlatformDispatcher.instance.locale.languageCode == 'fa' ? 'fa' : 'en');
  Locale get locale => Locale(language);
  ThemeMode get themeMode => _themeMode;
  bool get amoled => _amoled;
  int get accentIndex => _accentIndex;

  /// Jalali for Persian, Gregorian for English, unless chosen explicitly.
  CalendarSystem get calendar =>
      _calendar ?? (language == 'fa' ? CalendarSystem.jalali : CalendarSystem.gregorian);
  bool get showCompletedInInbox => _showCompletedInInbox;
  bool get smartParse => _smartParse;
  bool get haptics => _haptics;
  int get reminderHour => _reminderHour;

  void completeOnboarding() {
    _onboarded = true;
    _prefs.setBool(_kOnboarded, true);
    _prefs.setString(_kLanguage, language);
    notifyListeners();
  }

  set language(String value) {
    _language = value;
    _prefs.setString(_kLanguage, value);
    notifyListeners();
  }

  set themeMode(ThemeMode value) {
    _themeMode = value;
    _prefs.setString(_kTheme, value.name);
    notifyListeners();
  }

  set amoled(bool value) {
    _amoled = value;
    _prefs.setBool(_kAmoled, value);
    notifyListeners();
  }

  set accentIndex(int value) {
    _accentIndex = value;
    _prefs.setInt(_kAccent, value);
    notifyListeners();
  }

  set calendar(CalendarSystem value) {
    _calendar = value;
    _prefs.setString(_kCalendar, value.name);
    notifyListeners();
  }

  set showCompletedInInbox(bool value) {
    _showCompletedInInbox = value;
    _prefs.setBool(_kShowCompleted, value);
    notifyListeners();
  }

  set smartParse(bool value) {
    _smartParse = value;
    _prefs.setBool(_kSmartParse, value);
    notifyListeners();
  }

  set haptics(bool value) {
    _haptics = value;
    _prefs.setBool(_kHaptics, value);
    notifyListeners();
  }

  set reminderHour(int value) {
    _reminderHour = value;
    _prefs.setInt(_kReminderHour, value);
    notifyListeners();
  }
}
