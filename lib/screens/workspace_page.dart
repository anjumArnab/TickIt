// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/db_service.dart';
import '../widgets/task_group.dart';

class WorkspacePage extends StatefulWidget {
  final String workspaceName;

  const WorkspacePage({super.key, required this.workspaceName});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  bool isLoading = true;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  String selectedFilter = 'all'; // all, completed, pending

  @override
  void initState() {
    super.initState();
    _loadTasks();
    searchController.addListener(_filterTasks);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    setState(() {
      isLoading = true;
    });

    try {
      final workspaceTasks = DBService.instance.getTasksByWorkspace(
        widget.workspaceName,
      );
      setState(() {
        tasks = workspaceTasks;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading tasks: $e')));
    }
  }

  void _filterTasks() {
    setState(() {
      searchQuery = searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    filteredTasks =
        tasks.where((task) {
          // Search filter
          bool matchesSearch =
              searchQuery.isEmpty ||
              task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              task.subtasks.any(
                (subtask) => subtask.title.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              );

          // Status filter
          bool matchesStatus =
              selectedFilter == 'all' ||
              (selectedFilter == 'completed' &&
                  (task.isMainTaskCompleted || task.allSubtasksCompleted)) ||
              (selectedFilter == 'pending' &&
                  !task.isMainTaskCompleted &&
                  !task.allSubtasksCompleted);

          return matchesSearch && matchesStatus;
        }).toList();

    // Sort by date (newest first)
    filteredTasks.sort((a, b) => b.date.compareTo(a.date));
  }

  // Get workspace color
  Color _getWorkspaceColor() {
    if (tasks.isNotEmpty && tasks.first.workspaceColorValue != null) {
      return Color(tasks.first.workspaceColorValue!);
    }

    // Default colors based on workspace name
    switch (widget.workspaceName.toLowerCase()) {
      case 'personal':
        return const Color(0xFFFF6B6B);
      case 'work':
        return const Color(0xFF4A90E2);
      case 'freelance':
        return const Color(0xFF4ECDC4);
      case 'projects':
        return const Color(0xFFFFD93D);
      case 'study':
        return const Color(0xFFFF9500);
      case 'health':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF9B59B6);
    }
  }

  // Get task statistics
  Map<String, int> _getTaskStats() {
    final totalTasks = tasks.length;
    final completedTasks =
        tasks
            .where(
              (task) => task.isMainTaskCompleted || task.allSubtasksCompleted,
            )
            .length;
    final pendingTasks = totalTasks - completedTasks;

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
    };
  }

  // Handle task completion toggle
  void _toggleMainTaskCompletion(Task task) async {
    try {
      final taskKey = task.key as int;
      await DBService.instance.toggleMainTaskCompletion(taskKey);
      _loadTasks(); // Reload to reflect changes
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
    }
  }

  // Handle subtask completion toggle
  void _toggleSubtaskCompletion(Task task, int subtaskIndex) async {
    try {
      final taskKey = task.key as int;
      await DBService.instance.toggleSubtaskCompletion(taskKey, subtaskIndex);
      _loadTasks(); // Reload to reflect changes
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating subtask: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceColor = _getWorkspaceColor();
    final stats = _getTaskStats();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: workspaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.workspaceName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Compact header with stats
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: workspaceColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactStatCard(
                          'Total',
                          stats['total'].toString(),
                          Icons.assignment_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactStatCard(
                          'Done',
                          stats['completed'].toString(),
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactStatCard(
                          'Pending',
                          stats['pending'].toString(),
                          Icons.pending_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Compact search bar
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter tabs
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: TaskGroup(
                              title: task.title,
                              time: task.time,
                              progress: task.progress,
                              flagColor: Color(task.flagColorValue),
                              subtasks:
                                  task.subtasks.map((s) => s.title).toList(),
                              workspace: task.workspace,
                              workspaceColor:
                                  task.workspaceColorValue != null
                                      ? Color(task.workspaceColorValue!)
                                      : null,
                              isMainTaskCompleted: task.isMainTaskCompleted,
                              subtaskCompletionStates:
                                  task.subtasks
                                      .map((s) => s.isCompleted)
                                      .toList(),
                              onMainTaskToggle:
                                  () => _toggleMainTaskCompletion(task),
                              onSubtaskToggle:
                                  (subtaskIndex) => _toggleSubtaskCompletion(
                                    task,
                                    subtaskIndex,
                                  ),
                              onTap: () {
                                // You can add task detail navigation here
                              },
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _getWorkspaceColor() : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _getWorkspaceColor() : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    if (tasks.isEmpty) {
      message = 'No tasks in ${widget.workspaceName}';
      subtitle = 'Create some tasks to get started';
    } else if (searchQuery.isNotEmpty) {
      message = 'No tasks match your search';
      subtitle = 'Try a different search term';
    } else {
      message =
          selectedFilter == 'completed'
              ? 'No completed tasks'
              : 'No pending tasks';
      subtitle =
          selectedFilter == 'completed'
              ? 'Complete some tasks to see them here'
              : 'All tasks are completed!';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
