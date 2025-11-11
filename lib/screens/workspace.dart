import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/workspace_page.dart';
import '../widgets/workspace_card.dart';
import '../providers/task_provider.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key});

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  List<String> filteredWorkspaces = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterWorkspaces);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkspaces();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadWorkspaces() {
    final taskProvider = context.read<TaskProvider>();
    final workspaces = taskProvider.getAllWorkspaces();
    setState(() {
      filteredWorkspaces = workspaces;
    });
  }

  void _filterWorkspaces() {
    final taskProvider = context.read<TaskProvider>();
    final allWorkspaces = taskProvider.getAllWorkspaces();
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredWorkspaces =
          allWorkspaces
              .where((workspace) => workspace.toLowerCase().contains(query))
              .toList();
    });
  }

  Map<String, dynamic> _getWorkspaceStats(String workspace) {
    final taskProvider = context.read<TaskProvider>();
    final stats = taskProvider.getWorkspaceStats(workspace);
    final tasks = taskProvider.getTasksByWorkspace(workspace);

    DateTime? lastUpdated;
    if (tasks.isNotEmpty) {
      lastUpdated = tasks
          .map((task) => task.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    return {
      'taskCount': stats['total'],
      'completedCount': stats['completed'],
      'lastUpdated': lastUpdated,
    };
  }

  Color _getWorkspaceColor(String workspace) {
    final taskProvider = context.read<TaskProvider>();
    final tasks = taskProvider.getTasksByWorkspace(workspace);

    if (tasks.isNotEmpty && tasks.first.workspaceColorValue != null) {
      return Color(tasks.first.workspaceColorValue!);
    }

    switch (workspace.toLowerCase()) {
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
        final hash = workspace.hashCode;
        return Color.fromARGB(
          255,
          (hash & 0xFF0000) >> 16,
          (hash & 0x00FF00) >> 8,
          hash & 0x0000FF,
        );
    }
  }

  String _getWorkspaceIcon(String workspace) {
    switch (workspace.toLowerCase()) {
      case 'personal':
        return 'P';
      case 'work':
        return 'W';
      case 'freelance':
        return 'F';
      case 'projects':
        return 'Pr';
      case 'study':
        return 'S';
      case 'health':
        return 'H';
      default:
        return workspace.isNotEmpty ? workspace[0].toUpperCase() : 'W';
    }
  }

  String _formatLastUpdated(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'No tasks';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToWorkspace(String workspace) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkspacePage(workspaceName: workspace),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allWorkspaces = taskProvider.getAllWorkspaces();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Workspace',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search workspaces...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child:
                      filteredWorkspaces.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  allWorkspaces.isEmpty
                                      ? 'No workspaces found'
                                      : 'No workspaces match your search',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  allWorkspaces.isEmpty
                                      ? 'Create some tasks with workspaces to get started'
                                      : 'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: filteredWorkspaces.length,
                            itemBuilder: (context, index) {
                              final workspace = filteredWorkspaces[index];
                              final stats = _getWorkspaceStats(workspace);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: WorkspaceCard(
                                  title: workspace,
                                  taskCount: stats['taskCount'],
                                  completedCount: stats['completedCount'],
                                  lastUpdated: _formatLastUpdated(
                                    stats['lastUpdated'],
                                  ),
                                  color: _getWorkspaceColor(workspace),
                                  icon: _getWorkspaceIcon(workspace),
                                  onTap: () => _navigateToWorkspace(workspace),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
