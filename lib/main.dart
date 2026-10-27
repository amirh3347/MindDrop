import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/platform_bridge.dart';
import 'data/settings_store.dart';
import 'data/task_repository.dart';
import 'data/task_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  PlatformBridge.init();

  final settings = await SettingsStore.create();
  final notifications = NotificationService.instance..language = () => settings.language;
  await notifications.init();

  final store = TaskStore(
    FileTaskRepository(await getApplicationDocumentsDirectory()),
    reminders: notifications,
  );
  await store.load();
  // Keep scheduled reminders in sync with the stored tasks (e.g. after a
  // restore or a time zone change).
  store.rescheduleReminders();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: store),
      ],
      child: const MindDropApp(),
    ),
  );
}
