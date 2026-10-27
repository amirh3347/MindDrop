import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minddrop/app.dart';
import 'package:minddrop/data/settings_store.dart';
import 'package:minddrop/data/task_repository.dart';
import 'package:minddrop/data/task_store.dart';
import 'package:minddrop/models/task.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('onboarding, home and language switch render', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsStore.create();
    settings.language = 'en';
    final store = TaskStore(MemoryTaskRepository());
    await store.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: store),
        ],
        child: const MindDropApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose your language'), findsOneWidget);

    settings.completeOnboarding();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Your mind is clear'), findsOneWidget);

    store.add(Task.create(title: 'Write tests', tags: const ['dev'], priority: TaskPriority.high));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Write tests'), findsOneWidget);
    expect(find.text('#dev'), findsWidgets);

    settings.language = 'fa';
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('همه'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
