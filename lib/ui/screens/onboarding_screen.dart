import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/calendar.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/settings_store.dart';
import '../../data/task_store.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';
import '../common.dart';
import '../widgets/logo.dart';
import 'settings_screen.dart' show AccentPicker;

/// First-run flow: language → theme → features. Every choice applies live.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  static const _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final settings = context.read<SettingsStore>();
    final store = context.read<TaskStore>();
    await NotificationService.instance.requestPermission();
    if (store.tasks.isEmpty) _addSampleTasks(store, L10n(settings.language));
    settings.completeOnboarding();
  }

  void _addSampleTasks(TaskStore store, L10n l) {
    final today = dateOnly(DateTime.now());
    // Added oldest-first so the welcome task ends up on top.
    store.add(Task.create(title: l.t('sample4Title'), dueAt: addDays(today, 1)));
    store.add(Task.create(
      title: l.t('sample3Title'),
      tags: [l.t('sample3Tag')],
      priority: TaskPriority.high,
    ));
    store.add(Task.create(title: l.t('sample2Title'), dueAt: today));
    store.add(Task.create(
      title: l.t('sample1Title'),
      note: l.t('sample1Note'),
      pinned: true,
      subtasks: [
        Subtask.create(l.t('sample1Sub1')),
        Subtask.create(l.t('sample1Sub2')),
        Subtask.create(l.t('sample1Sub3')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (p) => setState(() => _page = p),
                children: const [_WelcomePage(), _ThemePage(), _ReadyPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? scheme.primary : scheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const Spacer(),
                  if (_page > 0)
                    TextButton(onPressed: () => _go(_page - 1), child: Text(l.t('back'))),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: last ? _finish : () => _go(_page + 1),
                    child: Text(
                      last ? l.t('getStarted') : l.t('next'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<SettingsStore>();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const AnimatedLogo(size: 170),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (rect) => kBrandGradient.createShader(rect),
            child: const Text(
              'MindDrop',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.t('obTagline'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.5, height: 1.6, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l.t('obChooseLanguage'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  selected: settings.language == 'fa',
                  onTap: () => settings.language = 'fa',
                  child: const Column(
                    children: [
                      Text('فا', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('فارسی', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceCard(
                  selected: settings.language == 'en',
                  onTap: () => settings.language = 'en',
                  child: const Column(
                    children: [
                      Text('En', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemePage extends StatelessWidget {
  const _ThemePage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<SettingsStore>();
    final scheme = Theme.of(context).colorScheme;
    final accent = accentAt(settings.accentIndex);

    Widget option(ThemeMode mode, String label, IconData icon, Brightness? preview) {
      return Expanded(
        child: _ChoiceCard(
          selected: settings.themeMode == mode,
          onTap: () => settings.themeMode = mode,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _ThemePreview(brightness: preview, accent: accent),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(l.t('obChooseTheme'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(l.t('obThemeHint'), style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          Row(
            children: [
              option(ThemeMode.dark, l.t('themeDark'), Icons.dark_mode_rounded, Brightness.dark),
              const SizedBox(width: 10),
              option(ThemeMode.light, l.t('themeLight'), Icons.light_mode_rounded, Brightness.light),
              const SizedBox(width: 10),
              option(ThemeMode.system, l.t('themeSystem'), Icons.brightness_auto_rounded, null),
            ],
          ),
          const SizedBox(height: 32),
          Text(l.t('obAccent'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          AccentPicker(
            selected: settings.accentIndex,
            onSelected: (i) => settings.accentIndex = i,
          ),
        ],
      ),
    );
  }
}

/// A tiny mock of the app in a given brightness (null = half dark, half light).
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.brightness, required this.accent});

  final Brightness? brightness;
  final Color accent;

  Widget _mock(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF0E0D1A) : const Color(0xFFF6F5FB);
    final card = dark ? const Color(0xFF1A192C) : Colors.white;
    final line = dark ? Colors.white24 : Colors.black12;
    Widget row(double width) => Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 1.5)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FractionallySizedBox(
                  widthFactor: width,
                  child: Container(height: 4, color: line),
                ),
              ),
            ],
          ),
        );
    return Container(
      color: bg,
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          row(0.9),
          row(0.6),
          row(0.75),
          const Spacer(),
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = brightness;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 120,
        child: b != null
            ? _mock(b)
            : Row(
                children: [
                  Expanded(child: _mock(Brightness.dark)),
                  Expanded(child: _mock(Brightness.light)),
                ],
              ),
      ),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final features = [
      (Icons.bolt_rounded, 'obFeature1', const Color(0xFFFBBF24)),
      (Icons.notifications_active_rounded, 'obFeature2', const Color(0xFFF472B6)),
      (Icons.search_rounded, 'obFeature3', const Color(0xFF22D3EE)),
      (Icons.lock_outline_rounded, 'obFeature4', const Color(0xFF34D399)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const MindDropLogo(size: 64),
          const SizedBox(height: 16),
          Text(l.t('obReadyTitle'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          for (final (icon, key, color) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('${key}Title'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.t('${key}Body'),
                          style: TextStyle(height: 1.5, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        haptic(context);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.14) : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
