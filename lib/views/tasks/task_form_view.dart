// lib/views/tasks/task_form_view.dart
// Formulaire de création et modification d'une tâche

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/task_controller.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';

class TaskFormView extends StatefulWidget {
  final Task? task; // null = création, non-null = modification

  const TaskFormView({super.key, this.task});

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _taskCtrl = TaskController();

  String _category = 'Général';
  int _priority = 1;
  DateTime? _dueDate;
  bool _isLoading = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.task!.title;
      _descCtrl.text = widget.task!.description;
      _category = widget.task!.category;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
      );
      await _taskCtrl.updateTask(updated);
    } else {
      await _taskCtrl.addTask(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
      );
    }

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEditing ? 'Tâche mise à jour !' : 'Tâche créée avec succès !'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la tâche' : 'Nouvelle tâche'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              const Text('Titre *',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: Faire la vaisselle',
                  prefixIcon:
                      Icon(Icons.title_rounded, color: AppTheme.primaryColor),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Titre requis';
                  if (v.trim().length < 2) return 'Minimum 2 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Détails optionnels...',
                  prefixIcon: Icon(Icons.notes_rounded,
                      color: AppTheme.primaryColor),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Catégorie
              const Text('Catégorie',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskController.categories
                    .where((c) => c != 'Toutes')
                    .map((cat) {
                  final isSelected = cat == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppTheme.getCategoryIcon(cat),
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Priorité
              const Text('Priorité',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _priorityButton(1, 'Basse', AppTheme.priorityLow),
                  const SizedBox(width: 8),
                  _priorityButton(2, 'Moyenne', AppTheme.priorityMedium),
                  const SizedBox(width: 8),
                  _priorityButton(3, 'Haute', AppTheme.priorityHigh),
                ],
              ),
              const SizedBox(height: 16),

              // Date d'échéance
              const Text('Date d\'échéance',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? DateFormat('dd MMMM yyyy', 'fr_FR')
                                .format(_dueDate!)
                            : 'Choisir une date (optionnel)',
                        style: TextStyle(
                          color: _dueDate != null ? null : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.clear_rounded,
                              size: 18, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing
                          ? 'Enregistrer les modifications'
                          : 'Créer la tâche'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityButton(int value, String label, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
