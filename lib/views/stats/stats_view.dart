// lib/views/stats/stats_view.dart
// Écran des statistiques avec graphiques

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/task_controller.dart';
import '../../utils/app_theme.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  final _taskCtrl = TaskController();

  @override
  Widget build(BuildContext context) {
    final tasks = _taskCtrl.tasks;
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending = tasks.length - completed;

    // Stats par catégorie
    final Map<String, int> byCategory = {};
    for (final t in tasks) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
    }

    // Stats par priorité
    final Map<int, int> byPriority = {1: 0, 2: 0, 3: 0};
    for (final t in tasks) {
      byPriority[t.priority] = (byPriority[t.priority] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune donnée à afficher',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé global
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('Total', tasks.length.toString(),
                              Icons.list_alt_rounded, AppTheme.primaryColor)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('Terminées', completed.toString(),
                              Icons.task_alt_rounded, AppTheme.successColor)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('En cours', pending.toString(),
                              Icons.pending_rounded, AppTheme.warningColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Diagramme circulaire progression
                  _sectionTitle('Progression globale'),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: completed.toDouble(),
                                  color: AppTheme.successColor,
                                  title:
                                      '${tasks.isEmpty ? 0 : (completed / tasks.length * 100).toInt()}%',
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                  radius: 70,
                                ),
                                PieChartSectionData(
                                  value: pending.toDouble(),
                                  color: Colors.grey.shade300,
                                  title: '',
                                  radius: 60,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _legendItem(AppTheme.successColor, 'Terminées'),
                            const SizedBox(height: 8),
                            _legendItem(Colors.grey.shade300, 'En cours'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Graphique par catégorie
                  if (byCategory.isNotEmpty) ...[
                    _sectionTitle('Par catégorie'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: byCategory.entries.map((e) {
                          final ratio = e.value / tasks.length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(AppTheme.getCategoryIcon(e.key),
                                        size: 14, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(e.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    const Spacer(),
                                    Text('${e.value} tâche(s)',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Graphique par priorité
                  _sectionTitle('Par priorité'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _priorityBar('Haute', byPriority[3]!, tasks.length,
                            AppTheme.priorityHigh),
                        const SizedBox(height: 10),
                        _priorityBar('Moyenne', byPriority[2]!, tasks.length,
                            AppTheme.priorityMedium),
                        const SizedBox(height: 10),
                        _priorityBar('Basse', byPriority[1]!, tasks.length,
                            AppTheme.priorityLow),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _priorityBar(String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
