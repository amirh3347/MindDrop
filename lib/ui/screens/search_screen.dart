import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/task_query.dart';
import '../../data/task_store.dart';
import '../../models/task.dart';
import '../common.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  StatusFilter _status = StatusFilter.all;
  final Set<TaskPriority> _priorities = {};
  final Set<String> _tags = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final store = context.watch<TaskStore>();
    final allTags = store.allTags;
    _tags.removeWhere((t) => !allTags.contains(t));

    final query = SearchQuery(
      text: _controller.text,
      status: _status,
      priorities: _priorities,
      tags: _tags,
    );
    final results = query.isEmpty ? const <Task>[] : searchTasks(store.tasks, query);
    final terms = _controller.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    Widget filterChip(String label, bool selected, VoidCallback onTap, {Color? color}) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: FilterChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            avatar: color == null ? null : Icon(Icons.flag_rounded, size: 16, color: color),
            onSelected: (_) => setState(onTap),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: l.t('searchHint'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_controller.clear),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final s in StatusFilter.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(switch (s) {
                        StatusFilter.all => l.t('filterAll'),
                        StatusFilter.active => l.t('filterActive'),
                        StatusFilter.done => l.t('filterDone'),
                      }),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ),
                const SizedBox(width: 8),
                for (final p in [TaskPriority.high, TaskPriority.medium, TaskPriority.low])
                  filterChip(
                    priorityLabel(p, l),
                    _priorities.contains(p),
                    () => _priorities.contains(p) ? _priorities.remove(p) : _priorities.add(p),
                    color: priorityColor(p, scheme),
                  ),
                const SizedBox(width: 8),
                for (final t in allTags)
                  filterChip(
                    '#$t',
                    _tags.contains(t),
                    () => _tags.contains(t) ? _tags.remove(t) : _tags.add(t),
                  ),
              ],
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? EmptyState(
                    title: l.t('searchIdle'),
                    body: l.t('searchIdleBody'),
                    icon: Icons.manage_search_rounded,
                  )
                : results.isEmpty
                    ? EmptyState(
                        title: l.t('noResults'),
                        body: l.t('noResultsBody'),
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: results.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return SectionLabel(l.f('resultsCount', {'count': results.length}));
                          }
                          final task = results[i - 1];
                          return TaskTile(key: ValueKey(task.id), task: task, highlight: terms);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
