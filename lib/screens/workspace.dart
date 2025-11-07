import 'package:flutter/material.dart';
import '../screens/workspace_page.dart';
import '../services/hive/db_service.dart';
import '../widgets/workspace_card.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key});

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  List<String> allWorkspaces = [];
  List<String> filteredWorkspaces = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
    searchController.addListener(_filterWorkspaces);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadWorkspaces() {
    try {
      final workspaces = DBService.instance.getAllWorkspaces();
      setState(() {
        allWorkspaces = workspaces;
        filteredWorkspaces = workspaces;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading workspaces: $e')),
      );
    }
  }

  void _filterWorkspaces() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredWorkspaces =
          allWorkspaces
              .where((workspace) => workspace.toLowerCase().contains(query))
              .toList();
    });
  }

  Map<String, dynamic> _getWorkspaceStats(String workspace) {
    try {
      final tasks = DBService.instance.getTasksByWorkspace(workspace);
      final completedTasks =
          tasks
              .where(
                (task) => task.isMainTaskCompleted || task.allSubtasksCompleted,
              )
              .length;

      DateTime? lastUpdated;
      if (tasks.isNotEmpty) {
        lastUpdated = tasks
            .map((task) => task.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }

      return {
        'taskCount': tasks.length,
        'completedCount': completedTasks,
        'lastUpdated': lastUpdated,
      };
    } catch (e) {
      return {'taskCount': 0, 'completedCount': 0, 'lastUpdated': null};
    }
  }

  Color _getWorkspaceColor(String workspace) {
    try {
      final tasks = DBService.instance.getTasksByWorkspace(workspace);
      if (tasks.isNotEmpty && tasks.first.workspaceColorValue != null) {
        return Color(tasks.first.workspaceColorValue!);
      }
    } catch (e) {
      // Fallback to default colors
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
  }
}