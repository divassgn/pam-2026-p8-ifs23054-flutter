// lib/features/todos/todos_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken;
    if (token != null) {
      context.read<TodoProvider>().loadTodos(authToken: token);
    }
  }

  void _onScroll() {
    // Trigger load more saat scroll mendekati bawah
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final token = context.read<AuthProvider>().authToken;
      if (token != null) {
        context.read<TodoProvider>().loadMoreTodos(authToken: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final token    = context.read<AuthProvider>().authToken ?? '';

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Todo Saya',
        withSearch: true,
        searchHint: 'Cari todo...',
        onSearchChanged: (query) {
          context.read<TodoProvider>().updateSearchQuery(query);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(RouteConstants.todosAdd).then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          // ── Filter Chips ──
          _FilterBar(
            currentFilter: provider.filter,
            totalAll: provider.totalTodos,
            totalDone: provider.doneTodos,
            totalPending: provider.pendingTodos,
            onFilterChanged: (f) =>
                context.read<TodoProvider>().setFilter(f),
          ),
          // ── Konten ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: switch (provider.status) {
                TodoStatus.loading || TodoStatus.initial =>
                const LoadingWidget(message: 'Memuat todo...'),
                TodoStatus.error => AppErrorWidget(
                    message: provider.errorMessage, onRetry: _loadData),
                _ => provider.todos.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .outline),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada todo.\nKetuk + untuk menambahkan.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: provider.todos.length +
                      (provider.isPaginating ? 1 : 0),
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    // Loading indicator di bawah saat paginasi
                    if (i == provider.todos.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: CircularProgressIndicator()),
                      );
                    }

                    final todo = provider.todos[i];
                    return _TodoCard(
                      todo: todo,
                      onTap: () => context
                          .push(RouteConstants.todosDetail(todo.id))
                          .then((_) => _loadData()),
                      onToggle: () async {
                        final success = await provider.editTodo(
                          authToken: token,
                          todoId: todo.id,
                          title: todo.title,
                          description: todo.description,
                          isDone: !todo.isDone,
                        );
                        if (!success && mounted) {
                          showAppSnackBar(context,
                              message: provider.errorMessage,
                              type: SnackBarType.error);
                        }
                      },
                    );
                  },
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ─────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.currentFilter,
    required this.totalAll,
    required this.totalDone,
    required this.totalPending,
    required this.onFilterChanged,
  });

  final TodoFilter currentFilter;
  final int totalAll;
  final int totalDone;
  final int totalPending;
  final ValueChanged<TodoFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(
              context,
              label: 'Semua ($totalAll)',
              filter: TodoFilter.all,
              icon: Icons.list_alt_rounded,
            ),
            const SizedBox(width: 8),
            _chip(
              context,
              label: 'Selesai ($totalDone)',
              filter: TodoFilter.done,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 8),
            _chip(
              context,
              label: 'Belum ($totalPending)',
              filter: TodoFilter.pending,
              icon: Icons.pending_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
      BuildContext context, {
        required String label,
        required TodoFilter filter,
        required IconData icon,
      }) {
    final selected = currentFilter == filter;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) => onFilterChanged(filter),
    );
  }
}

// ── Todo Card ───────────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  final todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: todo.isDone
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      color: todo.isDone
          ? Colors.green.withOpacity(0.05)
          : colorScheme.surface,
      child: ListTile(
        onTap: onTap,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              todo.isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(todo.isDone),
              color: todo.isDone ? Colors.green : colorScheme.outline,
              size: 28,
            ),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration:
            todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone ? colorScheme.outline : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: todo.description.isNotEmpty
            ? Text(
          todo.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: todo.isDone
                ? colorScheme.outline.withOpacity(0.6)
                : null,
          ),
        )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
