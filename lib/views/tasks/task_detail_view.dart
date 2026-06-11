// lib/views/tasks/task_detail_view.dart
// Écran de détail d'une tâche

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../controllers/task_controller.dart';
import '../../utils/app_theme.dart';
import 'task_form_view.dart';

class TaskDetailView extends StatefulWidget {
  final Task task;

  const TaskDetailView({super.key, required this.task});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late Task _task;
  final _taskCtrl = TaskController();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: const Text(
            'Cette action est irréversible. Confirmer la suppression ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      await _taskCtrl.deleteTask(_task.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.getPriorityColor(_task.priority);
    final isDue = _task.dueDate != null &&
        _task.dueDate!.isBefore(DateTime.now()) &&
        !_task.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la tâche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskFormView(task: _task)),
              );
              // Recharger la tâche depuis le controller
              final updated = _taskCtrl.tasks
                  .firstWhere((t) => t.id == _task.id, orElse: () => _task);
              setState(() => _task = updated);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la tâche
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: priorityColor, width: 5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _task.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            decoration: _task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _task.isCompleted
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _task.isCompleted ? 'Terminée' : 'En cours',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (_task.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _task.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Informations détaillées
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow(
                    Icons.label_rounded,
                    'Catégorie',
                    _task.category,
                    AppTheme.primaryColor,
                  ),
                  const Divider(),
                  _infoRow(
                    Icons.flag_rounded,
                    'Priorité',
                    _task.priorityLabel,
                    priorityColor,
                  ),
                  const Divider(),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    'Créée le',
                    DateFormat('dd/MM/yyyy à HH:mm').format(_task.createdAt),
                    Colors.grey,
                  ),
                  if (_task.dueDate != null) ...[
                    const Divider(),
                    _infoRow(
                      Icons.event_rounded,
                      'Échéance',
                      DateFormat('dd/MM/yyyy').format(_task.dueDate!),
                      isDue ? AppTheme.errorColor : Colors.grey,
                      subtitle: isDue ? 'En retard !' : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton pour basculer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _taskCtrl.toggleTaskComplete(_task.id);
                  final updated = _taskCtrl.tasks
                      .firstWhere((t) => t.id == _task.id, orElse: () => _task);
                  setState(() => _task = updated);
                },
                icon: Icon(_task.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_rounded),
                label: Text(_task.isCompleted
                    ? 'Marquer comme non terminée'
                    : 'Marquer comme terminée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _task.isCompleted
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color,
      {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: color)),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.errorColor, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
