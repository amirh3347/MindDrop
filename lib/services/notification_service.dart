import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/l10n.dart';
import '../core/platform_bridge.dart';
import '../data/task_store.dart';
import '../models/task.dart';

/// Reminder notifications backed by flutter_local_notifications.
class NotificationService implements ReminderScheduler {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _launchTaskId;

  /// Language used for notification texts.
  String Function() language = () => 'en';

  /// Called when the user taps a reminder while the app is running.
  ValueChanged<String>? onOpenTask;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final zone = await PlatformBridge.timeZone();
      try {
        tz.setLocalLocation(tz.getLocation(zone ?? 'UTC'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id != null && id.isNotEmpty) onOpenTask?.call(id);
        },
      );

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        _launchTaskId = launch.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Task id of the reminder that launched the app, if any. Consumed on read.
  String? takeLaunchTaskId() {
    final id = _launchTaskId;
    _launchTaskId = null;
    return id;
  }

  Future<bool> areEnabled() async {
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details(L10n l) => NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          l.t('notifChannel'),
          channelDescription: l.t('notifChannelDesc'),
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF7C5CFF),
        ),
      );

  @override
  Future<void> schedule(Task task) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(task.notificationId);
      final at = task.remindAt;
      if (task.done || at == null || !at.isAfter(DateTime.now())) return;

      final l = L10n(language());
      final note = task.note.trim();
      final body = note.isEmpty ? l.t('notifBody') : note.split('\n').first;
      final when = tz.TZDateTime.from(at, tz.local);
      final details = _details(l);
      try {
        await _plugin.zonedSchedule(
          task.notificationId,
          task.title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: task.id,
        );
      } catch (_) {
        // Exact alarms not permitted on this device: a few minutes late is fine.
        await _plugin.zonedSchedule(
          task.notificationId,
          task.title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      }
    } catch (e) {
      debugPrint('Scheduling reminder failed: $e');
    }
  }

  @override
  Future<void> cancel(Task task) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(task.notificationId);
    } catch (_) {
      // Nothing scheduled.
    }
  }

  @override
  Future<void> rescheduleAll(List<Task> tasks) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Nothing scheduled.
    }
    for (final t in tasks) {
      if (!t.done && t.remindAt != null) await schedule(t);
    }
  }
}
