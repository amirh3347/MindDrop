import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/calendar.dart';
import '../../core/l10n.dart';
import '../../core/platform_bridge.dart';
import '../../core/theme.dart';
import '../../data/settings_store.dart';
import '../../data/task_query.dart';
import '../../data/task_store.dart';
import '../../services/notification_service.dart';
import '../common.dart';
import '../task_actions.dart';
import '../widgets/empty_state.dart';
import '../widgets/logo.dart';
import '../widgets/task_tile.dart';
import 'quick_add_sheet.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskView _view = TaskView.inbox;
  String? _tag;

  @override
  void initState() {
    super.initState();
    PlatformBridge.onAction = _handleAction;
    NotificationService.instance.onOpenTask = _openTaskById;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final taskId = NotificationService.instance.takeLaunchTaskId();
      if (taskId != null) {
        _openTaskById(taskId);
        return;
      }
      final action = await PlatformBridge.takeLaunchAction();
      if (action != null) _handleAction(action);
    });
  }

  @override
  void dispose() {
    PlatformBridge.onAction = null;
    NotificationService.instance.onOpenTask = null;
    super.dispose();
  }

  void _handleAction(LaunchAction action) {
    if (!mounted) return;
    final context = navigatorKey.currentContext ?? this.context;
    switch (action.type) {
      case LaunchActionType.newTask:
        showQuickAdd(context);
      case LaunchActionType.search:
        _openSearch();
      case LaunchActionType.share:
        // Shared text: first line becomes the title, the rest the note.
        final subject = action.subject?.trim() ?? '';
        final text = action.text.trim();
        final lines = text.split('\n');
        final String title;
        final String note;
        if (subject.isNotEmpty && subject != text) {
          title = subject;
          note = text;
        } else if (lines.first.length <= 120) {
          title = lines.first.trim();
          note = lines.skip(1).join('\n').trim();
        } else {
          title = '';
          note = text;
        }
        showQuickAdd(context, text: title, note: note);
    }
  }

  void _openTaskById(String id) {
    final task = context.read<TaskStore>().byId(id);
    final navContext = navigatorKey.currentContext;
    if (task == null || navContext == null) return;
    openTaskEditor(navContext, task: task);
  }

  void _openSearch() {
    Navigator.of(navigatorKey.currentContext ?? context).push(
      MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _clearCompleted(int count) async {
    final l = context.l10n;
    final store = context.read<TaskStore>();
    final ok = await confirmDialog(
      context,
      title: l.t('clearCompleted'),
      message: l.f('clearCompletedConfirm', {'count': count}),
      confirmLabel: l.t('delete'),
      destructive: true,
    );
    if (!ok) return;
    final removed = store.clearCompleted();
    showSnack(
      l.f('tasksDeleted', {'count': removed.length}),
      actionLabel: l.t('undo'),
      onAction: () => store.restore(removed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = context.watch<TaskStore>();
    final settings = context.watch<SettingsStore>();
    final now = DateTime.now();
    final tasks = store.tasks;
    final todayCount = dueTodayCount(tasks, now);
    final tags = store.allTags;
    if (_tag != null && !tags.contains(_tag)) _tag = null;

    final sections = buildSections(
      tasks,
      _view,
      now,
      showCompleted: settings.showCompletedInInbox,
      tag: _view == TaskView.inbox ? _tag : null,
    );
    final doneCount = tasks.where((t) => t.done).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                onSearch: _openSearch,
                onStats: () => _push(const StatsScreen()),
                onSettings: () => _push(const SettingsScreen()),
              ),
            ),
            if (_view == TaskView.inbox || _view == TaskView.today)
              const SliverToBoxAdapter(child: _SummaryCard()),
            if (_view == TaskView.inbox && tags.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: ChoiceChip(
                          label: Text(l.t('allTags')),
                          selected: _tag == null,
                          onSelected: (_) => setState(() => _tag = null),
                        ),
                      ),
                      for (final tag in tags)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: ChoiceChip(
                            label: Text('#$tag'),
                            selected: _tag == tag,
                            onSelected: (sel) => setState(() => _tag = sel ? tag : null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!store.loaded)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (sections.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _emptyFor(l))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList.list(
                  children: [
                    for (final section in sections) ...[
                      SectionLabel(
                        _sectionTitle(section, l, calendarOf(context)),
                        count: section.tasks.length,
                        color: section.kind == SectionKind.overdue ? kDanger : null,
                        trailing: _view == TaskView.done && section == sections.first
                            ? TextButton.icon(
                                onPressed: () => _clearCompleted(doneCount),
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                                label: Text(l.t('clearCompleted')),
                              )
                            : null,
                      ),
                      for (final task in section.tasks) TaskTile(key: ValueKey(task.id), task: task),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          haptic(context);
          showQuickAdd(context);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.t('fabNew'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _view.index,
        onDestinationSelected: (i) {
          haptic(context);
          setState(() => _view = TaskView.values[i]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox_rounded),
            label: l.t('tabInbox'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: todayCount > 0,
              label: Text(l.n(todayCount)),
              child: const Icon(Icons.today_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: todayCount > 0,
              label: Text(l.n(todayCount)),
              child: const Icon(Icons.today_rounded),
            ),
            label: l.t('tabToday'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.upcoming_outlined),
            selectedIcon: const Icon(Icons.upcoming_rounded),
            label: l.t('tabUpcoming'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt_rounded),
            label: l.t('tabDone'),
          ),
        ],
      ),
    );
  }

  Widget _emptyFor(L10n l) {
    return switch (_view) {
      TaskView.inbox => EmptyState(title: l.t('emptyInboxTitle'), body: l.t('emptyInboxBody')),
      TaskView.today => EmptyState(
          title: l.t('emptyTodayTitle'),
          body: l.t('emptyTodayBody'),
          icon: Icons.wb_sunny_outlined,
        ),
      TaskView.upcoming => EmptyState(
          title: l.t('emptyUpcomingTitle'),
          body: l.t('emptyUpcomingBody'),
          icon: Icons.event_available_outlined,
        ),
      TaskView.done => EmptyState(
          title: l.t('emptyDoneTitle'),
          body: l.t('emptyDoneBody'),
          icon: Icons.emoji_events_outlined,
        ),
    };
  }

  String _sectionTitle(TaskSection section, L10n l, AppCalendar cal) {
    return switch (section.kind) {
      SectionKind.pinned => l.t('secPinned'),
      SectionKind.overdue => l.t('secOverdue'),
      SectionKind.today => l.t('secToday'),
      SectionKind.upcoming => l.t('secUpcoming'),
      SectionKind.someday => l.t('secSomeday'),
      SectionKind.completed => l.t('secCompleted'),
      SectionKind.day => _dayTitle(section.date!, l, cal),
    };
  }

  String _dayTitle(DateTime date, L10n l, AppCalendar cal) {
    final rel = relativeDate(date, l, cal);
    final full = cal.fullDate(date);
    // "Tomorrow · Wednesday 6 Aban 1405" or just the full date.
    return rel == cal.shortDate(date) ? full : '$rel · $full';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onStats, required this.onSettings});

  final VoidCallback onSearch;
  final VoidCallback onStats;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cal = calendarOf(context);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      >= 5 && < 12 => l.t('greetingMorning'),
      >= 12 && < 17 => l.t('greetingAfternoon'),
      >= 17 && < 21 => l.t('greetingEvening'),
      _ => l.t('greetingNight'),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 4),
      child: Row(
        children: [
          const MindDropLogo(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => kBrandGradient.createShader(rect),
                  child: const Text(
                    'MindDrop',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  '$greeting · ${cal.fullDate(now)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.t('search'),
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: l.t('stats'),
            onPressed: onStats,
            icon: const Icon(Icons.insights_rounded),
          ),
          IconButton(
            tooltip: l.t('settings'),
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

/// Today's progress at a glance.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tasks = context.watch<TaskStore>().tasks;
    final now = DateTime.now();

    final dueToday = tasks.where((t) => !t.done && isDueToday(t, now) && !isOverdue(t, now)).length;
    final overdue = tasks.where((t) => isOverdue(t, now)).length;
    final doneToday =
        tasks.where((t) => t.done && t.completedAt != null && isSameDay(t.completedAt!, now)).length;
    final open = tasks.where((t) => !t.done).length;
    final total = doneToday + dueToday + overdue;
    final progress = total == 0 ? 0.0 : doneToday / total;

    final String headline;
    if (dueToday == 0 && overdue == 0) {
      headline = l.t('summaryClear');
    } else {
      headline = [
        if (dueToday > 0) l.f('summaryToday', {'count': dueToday}),
        if (overdue > 0) l.f('summaryOverdue', {'count': overdue}),
      ].join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              scheme.primary.withValues(alpha: 0.28),
              scheme.tertiary.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${l.n((progress * 100).round())}%',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? l.f('summaryActive', {'count': open})
                        : l.f('todayProgress', {'done': doneToday, 'total': total}),
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
