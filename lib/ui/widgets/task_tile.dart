import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/task_query.dart';
import '../../models/task.dart';
import '../common.dart';
import '../task_actions.dart';

/// A task card: tap to edit, long-press for a menu, swipe toward the end to
/// complete and toward the start to delete.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.highlight = const []});

  final Task task;

  /// Lower-cased search words to highlight in the title.
  final List<String> highlight;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Dismissible(
          // The key includes `done` so a completed task re-enters the list as a
          // new widget instead of colliding with the dismissed one.
          key: ValueKey('${task.id}-${task.done}'),
          background: _SwipeBackground(
            color: kSuccess,
            icon: task.done ? Icons.undo_rounded : Icons.check_rounded,
            label: task.done ? l.t('swipeUndo') : l.t('swipeDone'),
            alignment: AlignmentDirectional.centerStart,
          ),
          secondaryBackground: _SwipeBackground(
            color: kDanger,
            icon: Icons.delete_outline_rounded,
            label: l.t('swipeDelete'),
            alignment: AlignmentDirectional.centerEnd,
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              toggleTaskDone(context, task);
            } else {
              deleteTaskWithUndo(context, task);
            }
          },
          child: _TaskCard(task: task, highlight: highlight),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.highlight});

  final Task task;
  final List<String> highlight;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cal = calendarOf(context);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final pColor = priorityColor(task.priority, scheme);
    final overdue = isOverdue(task, now);

    final titleStyle = TextStyle(
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: task.done ? scheme.onSurfaceVariant : scheme.onSurface,
      decoration: task.done ? TextDecoration.lineThrough : null,
      decorationColor: scheme.onSurfaceVariant,
    );

    final meta = <Widget>[
      if (task.dueAt != null)
        _MetaChip(
          icon: task.hasDueTime ? Icons.schedule_rounded : Icons.event_rounded,
          label: relativeDate(task.dueAt!, l, cal, withTime: task.hasDueTime),
          color: overdue
              ? kDanger
              : isDueToday(task, now)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
        ),
      if (task.remindAt != null && !task.done)
        _MetaChip(icon: Icons.notifications_active_outlined, color: scheme.tertiary),
      if (task.priority != TaskPriority.none && !task.done)
        _MetaChip(
          icon: Icons.flag_rounded,
          label: priorityLabel(task.priority, l),
          color: pColor,
        ),
      if (task.subtasks.isNotEmpty)
        _MetaChip(
          icon: Icons.checklist_rounded,
          label: '${l.n(task.subtasksDone)}/${l.n(task.subtasks.length)}',
          color: task.subtasksDone == task.subtasks.length ? kSuccess : scheme.onSurfaceVariant,
        ),
      for (final tag in task.tags)
        Text(
          '#$tag',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: scheme.primary.withValues(alpha: task.done ? 0.6 : 1),
          ),
        ),
    ];

    return Material(
      color: scheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: task.pinned && !task.done
            ? BorderSide(color: scheme.primary.withValues(alpha: 0.45), width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => openTaskEditor(context, task: task),
        onLongPress: () => showTaskMenu(context, task),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckCircle(
                done: task.done,
                color: task.priority == TaskPriority.none ? scheme.primary : pColor,
                ringColor: pColor,
                onTap: () => toggleTaskDone(context, task),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: titleStyle,
                          children: highlightSpans(
                            task.title,
                            highlight,
                            TextStyle(
                              backgroundColor: scheme.primary.withValues(alpha: 0.25),
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.note.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.note.trim().split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      if (meta.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: meta,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (task.pinned)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6, top: 6),
                  child: Icon(Icons.push_pin_rounded, size: 16, color: scheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, this.label, required this.color});

  final IconData icon;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: label == null ? 5 : 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.done,
    required this.color,
    required this.ringColor,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 44,
        height: 40,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color : Colors.transparent,
              border: Border.all(color: done ? color : ringColor, width: 2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: done
                  ? const Icon(Icons.check_rounded, key: ValueKey(true), size: 16, color: Colors.white)
                  : const SizedBox.shrink(key: ValueKey(false)),
            ),
          ),
        ),
      ),
    );
  }
}
