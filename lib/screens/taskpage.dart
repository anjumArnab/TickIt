// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tick_it/providers/task_provider.dart';
import '../models/hive/task.dart';

class TaskPage extends StatefulWidget {
  final Task? task;
  final int? taskKey;
  const TaskPage({super.key, this.task, this.taskKey});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtaskController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Color _selectedFlagColor = Colors.red;
  String? _selectedWorkspace;
  Color? _selectedWorkspaceColor;
  List<Subtask> _subtasks = [];

  bool _isEditing = false;
  int? _taskKey;

  final Map<String, Color> _workspaces = {
    'Personal': const Color(0xFFFF6B6B),
    'Work': const Color(0xFF4A90E2),
    'Freelance': const Color(0xFF4ECDC4),
    'Projects': const Color(0xFFFFD93D),
  };

  final List<Color> _flagColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null && widget.taskKey != null) {
      _populateFieldsForEditing();
    }
  }

  void _populateFieldsForEditing() {
    final task = widget.task!;
    _isEditing = true;
    _taskKey = widget.taskKey;

    _titleController.text = task.title;
    _selectedDate = task.date;

    try {
      final timeParts = task.time.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1].split(' ')[0]);

        if (task.time.toLowerCase().contains('pm') && hour != 12) {
          hour += 12;
        } else if (task.time.toLowerCase().contains('am') && hour == 12) {
          hour = 0;
        }

        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      _selectedTime = TimeOfDay.now();
    }

    _selectedFlagColor = Color(task.flagColorValue);
    _selectedWorkspace = task.workspace;

    if (task.workspaceColorValue != null) {
      _selectedWorkspaceColor = Color(task.workspaceColorValue!);
    }

    _subtasks = List.from(task.subtasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'Add New Task',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _deleteTask,
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 15),
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF4A90E2),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter task title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            icon: Icons.calendar_today,
                            label: _formatDate(_selectedDate),
                            onTap: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimeButton(
                            icon: Icons.access_time,
                            label: _selectedTime.format(context),
                            onTap: _selectTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workspace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _workspaces.entries.map((entry) {
                            final isSelected = _selectedWorkspace == entry.key;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedWorkspace = entry.key;
                                  _selectedWorkspaceColor = entry.value;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? entry.value.withOpacity(0.2)
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? entry.value
                                            : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: entry.value,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? entry.value
                                                : Colors.black87,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children:
                          _flagColors.map((color) {
                            final isSelected = _selectedFlagColor == color;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFlagColor = color;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_subtasks.length} items',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Add a subtask...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: _addSubtask,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _addSubtask(_subtaskController.text),
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4A90E2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._subtasks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final subtask = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtask.title,
                                style: TextStyle(
                                  color:
                                      subtask.isCompleted
                                          ? Colors.grey[500]
                                          : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeSubtask(index),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addSubtask(String subtaskTitle) {
    if (subtaskTitle.trim().isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(title: subtaskTitle.trim()));
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final task = Task(
          title: _titleController.text.trim(),
          time: _selectedTime.format(context),
          flagColorValue: _selectedFlagColor.value,
          subtasks: _subtasks,
          date: _selectedDate,
          workspace: _selectedWorkspace,
          workspaceColorValue: _selectedWorkspaceColor?.value,
        );

        final taskProvider = context.read<TaskProvider>();

        if (_isEditing && _taskKey != null) {
          await taskProvider.updateTask(_taskKey!, task);
        } else {
          await taskProvider.addTask(task);
        }

        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          Navigator.pop(context, true);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Task updated successfully!'
                    : 'Task created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTask() async {
    if (!_isEditing || _taskKey == null) {
      _clearFields();
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        await context.read<TaskProvider>().deleteTask(_taskKey!);

        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          Navigator.pop(context, true);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _clearFields() {
    _titleController.clear();
    _subtaskController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedFlagColor = Colors.red;
      _selectedWorkspace = null;
      _selectedWorkspaceColor = null;
      _subtasks.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task cleared!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
