import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/platform_bridge.dart';
import '../../core/theme.dart';
import '../../data/backup.dart';
import '../../data/settings_store.dart';
import '../../data/task_store.dart';
import '../../services/notification_service.dart';
import '../common.dart';
import '../widgets/logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool? _notificationsOn;
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNotifications();
    PlatformBridge.appVersion().then((v) {
      if (mounted && v != null) setState(() => _version = v);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have changed the permission in system settings.
    if (state == AppLifecycleState.resumed) _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    final on = await NotificationService.instance.areEnabled();
    if (mounted) setState(() => _notificationsOn = on);
  }

  Future<void> _requestNotifications() async {
    final l = context.l10n;
    final granted = await NotificationService.instance.requestPermission();
    await _refreshNotifications();
    if (!granted && _notificationsOn != true) showSnack(l.t('notifDenied'));
  }

  Future<void> _export({required bool share}) async {
    final l = context.l10n;
    final tasks = context.read<TaskStore>().tasks;
    final now = DateTime.now();
    final json = encodeBackup(tasks, now: now);
    final name = backupFileName(now);
    try {
      if (share) {
        await PlatformBridge.shareFile(name, json, subject: 'MindDrop backup');
      } else {
        final saved = await PlatformBridge.saveFile(name, json);
        if (saved == true) showSnack(l.t('exportDone'));
      }
    } on PlatformException {
      showSnack(l.t('exportFailed'));
    } on MissingPluginException {
      showSnack(l.t('exportFailed'));
    }
  }

  Future<void> _import() async {
    final l = context.l10n;
    final store = context.read<TaskStore>();
    final String? raw;
    try {
      raw = await PlatformBridge.openFile();
    } on PlatformException {
      showSnack(l.t('importFailed'));
      return;
    } on MissingPluginException {
      showSnack(l.t('importFailed'));
      return;
    }
    if (raw == null || !mounted) return;

    final BackupData data;
    try {
      data = decodeBackup(raw);
    } on BackupException catch (e) {
      showSnack(switch (e.error) {
        BackupError.notJson => l.t('importNotJson'),
        BackupError.notMindDrop => l.t('importNotMindDrop'),
        BackupError.newerVersion => l.t('importNewer'),
      });
      return;
    }
    if (data.tasks.isEmpty) {
      showSnack(l.t('importEmpty'));
      return;
    }

    final cal = calendarOf(context, listen: false);
    final exportedAt = data.exportedAt;
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restore_rounded),
        title: Text(l.t('importTitle')),
        content: Text(
          [
            l.f('importSummary', {'count': data.tasks.length}),
            if (exportedAt != null) l.f('importExported', {'date': cal.dateTime(exportedAt.toLocal())}),
            '',
            l.t('importHow'),
          ].join('\n'),
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            child: Text(l.t('replace'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          FilledButton(onPressed: () => Navigator.pop(context, 'merge'), child: Text(l.t('merge'))),
        ],
      ),
    );
    if (mode == null) return;
    final result = store.importTasks(data.tasks, replace: mode == 'replace');
    showSnack(l.f('importDone', {'added': result.added, 'updated': result.updated}));
  }

  Future<void> _deleteAll() async {
    final l = context.l10n;
    final store = context.read<TaskStore>();
    final ok = await confirmDialog(
      context,
      title: l.t('deleteAll'),
      message: l.f('deleteAllConfirm', {'count': store.tasks.length}),
      confirmLabel: l.t('delete'),
      destructive: true,
    );
    if (!ok) return;
    final removed = store.deleteAll();
    showSnack(l.t('allDeleted'), actionLabel: l.t('undo'), onAction: () => store.restore(removed));
  }

  Future<void> _pickReminderHour() async {
    final settings = context.read<SettingsStore>();
    final time = await pickTime(context, TimeOfDay(hour: settings.reminderHour, minute: 0));
    if (time != null) settings.reminderHour = time.hour;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<SettingsStore>();
    final taskCount = context.select<TaskStore, int>((s) => s.tasks.length);
    final scheme = Theme.of(context).colorScheme;
    final cal = calendarOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _Group(
            title: l.t('appearance'),
            children: [
              _Labeled(
                label: l.t('theme'),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_rounded),
                      label: Text(l.t('themeDark')),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_rounded),
                      label: Text(l.t('themeLight')),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_rounded),
                      label: Text(l.t('themeSystem')),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.themeMode = s.first,
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.contrast_rounded),
                title: Text(l.t('amoled')),
                subtitle: Text(l.t('amoledDesc')),
                value: settings.amoled,
                onChanged: settings.themeMode == ThemeMode.light ? null : (v) => settings.amoled = v,
              ),
              _Labeled(
                label: l.t('accent'),
                child: AccentPicker(
                  selected: settings.accentIndex,
                  onSelected: (i) => settings.accentIndex = i,
                ),
              ),
            ],
          ),
          _Group(
            title: l.t('language'),
            children: [
              _Labeled(
                label: l.t('language'),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'fa', label: Text('فارسی')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {settings.language},
                  onSelectionChanged: (s) => settings.language = s.first,
                ),
              ),
              _Labeled(
                label: l.t('calendar'),
                child: SegmentedButton<CalendarSystem>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: CalendarSystem.jalali, label: Text(l.t('calJalali'))),
                    ButtonSegment(value: CalendarSystem.gregorian, label: Text(l.t('calGregorian'))),
                  ],
                  selected: {settings.calendar},
                  onSelectionChanged: (s) => settings.calendar = s.first,
                ),
              ),
            ],
          ),
          _Group(
            title: l.t('behavior'),
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.auto_awesome_rounded),
                title: Text(l.t('smartParse')),
                subtitle: Text(l.t('smartParseDesc')),
                value: settings.smartParse,
                onChanged: (v) => settings.smartParse = v,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.done_all_rounded),
                title: Text(l.t('showCompleted')),
                value: settings.showCompletedInInbox,
                onChanged: (v) => settings.showCompletedInInbox = v,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_rounded),
                title: Text(l.t('haptics')),
                value: settings.haptics,
                onChanged: (v) => settings.haptics = v,
              ),
              ListTile(
                leading: const Icon(Icons.alarm_rounded),
                title: Text(l.t('reminderTime')),
                subtitle: Text(l.t('reminderTimeDesc')),
                trailing: Text(
                  cal.time(DateTime(2000, 1, 1, settings.reminderHour)),
                  style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
                ),
                onTap: _pickReminderHour,
              ),
            ],
          ),
          _Group(
            title: l.t('notifications'),
            children: [
              ListTile(
                leading: Icon(
                  _notificationsOn == true
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: _notificationsOn == true ? kSuccess : scheme.error,
                ),
                title: Text(
                  _notificationsOn == true ? l.t('notifEnabled') : l.t('notifDisabled'),
                ),
                onTap: _notificationsOn == true ? null : _requestNotifications,
              ),
            ],
          ),
          _Group(
            title: l.t('data'),
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt_rounded),
                title: Text(l.t('exportFile')),
                subtitle: Text(l.t('exportFileDesc')),
                onTap: () => _export(share: false),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded),
                title: Text(l.t('shareBackup')),
                subtitle: Text(l.t('shareBackupDesc')),
                onTap: () => _export(share: true),
              ),
              ListTile(
                leading: const Icon(Icons.file_open_outlined),
                title: Text(l.t('importFile')),
                subtitle: Text(l.t('importFileDesc')),
                onTap: _import,
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
                title: Text(l.t('deleteAll'), style: TextStyle(color: scheme.error)),
                enabled: taskCount > 0,
                onTap: _deleteAll,
              ),
            ],
          ),
          _Group(
            title: l.t('about'),
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const MindDropLogo(size: 72),
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (rect) => kBrandGradient.createShader(rect),
                      child: const Text(
                        'MindDrop',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    if (_version.isNotEmpty)
                      Text(
                        l.f('version', {'v': cal.digits(_version)}),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      l.t('aboutBody'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.7),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.f('taskCount', {'count': taskCount}),
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row of accent color swatches.
class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key, required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < kAccents.length; i++)
          GestureDetector(
            onTap: () {
              haptic(context);
              onSelected(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kAccents[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: i == selected
                    ? [BoxShadow(color: kAccents[i].withValues(alpha: 0.5), blurRadius: 12)]
                    : null,
              ),
              child: i == selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title, color: Theme.of(context).colorScheme.primary),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
