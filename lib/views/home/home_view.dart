// lib/views/home/home_view.dart
// Écran principal avec la liste des tâches

import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_theme.dart';
import '../tasks/task_form_view.dart';
import '../tasks/task_detail_view.dart';
import '../stats/stats_view.dart';
import '../auth/login_view.dart';
import 'widgets/task_card.dart';
import 'widgets/category_filter.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/stats_summary.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final _taskCtrl = TaskController();
  final _auth = AuthController();
  final _themeCtrl = ThemeController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _taskCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskCtrl.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor),
              child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.logout();
      _taskCtrl.reset();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final pending =
        _taskCtrl.filteredTasks.where((t) => !t.isCompleted).toList();
    final completed =
        _taskCtrl.filteredTasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('TaskMaster'),
            Text(
              'Bonjour, ${user?.username ?? ''} 👋',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _themeCtrl.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () async {
              await _themeCtrl.toggleTheme();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SearchBarWidget(
                  onChanged: _taskCtrl.setSearchQuery,
                ),
              ),
              const SizedBox(height: 4),
              CategoryFilter(
                categories: TaskController.categories,
                selected: _taskCtrl.selectedCategory,
                onSelected: _taskCtrl.setCategory,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Mini stats résumé
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatsSummary(
              total: _taskCtrl.tasks.length,
              completed: _taskCtrl.completedTasks.length,
              pending: _taskCtrl.pendingTasks.length,
            ),
          ),
          // Onglets
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'En cours (${pending.length})'),
                Tab(text: 'Terminées (${completed.length})'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Liste des tâches
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(pending, 'Aucune tâche en cours'),
                _buildTaskList(completed, 'Aucune tâche terminée'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormView()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle tâche'),
      ),
    );
  }

  Widget _buildTaskList(List tasks, String emptyMessage) {
    if (_taskCtrl.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded,
                size: 80, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: tasks.length,
      itemBuilder: (_, i) => TaskCard(
        task: tasks[i],
        onToggle: () => _taskCtrl.toggleTaskComplete(tasks[i].id),
        onDelete: () => _taskCtrl.deleteTask(tasks[i].id),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailView(task: tasks[i])),
        ),
      ),
    );
  }
}
