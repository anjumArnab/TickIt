import 'package:flutter/material.dart';
import 'package:tick_it/services/notification_service.dart';
import '../models/hive/task.dart';
import '../services/hive/db_service.dart';

class TaskProvider extends ChangeNotifier {
  final DBService _dbService = DBService.instance;
  final NotificationService _notificationService = NotificationService();

  // State variables
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  DateTime? _selectedDate;
  bool _isDateFiltered = false;
  String _searchQuery = '';
  String _selectedWorkspace = '';

  // Getters
  List<Task> get allTasks => _allTasks;
  List<Task> get filteredTasks => _filteredTasks;
  bool get isLoading => _isLoading;
  DateTime? get selectedDate => _selectedDate;
  bool get isDateFiltered => _isDateFiltered;
  String get searchQuery => _searchQuery;
  String get selectedWorkspace => _selectedWorkspace;

  /// Initialize and load tasks
  Future<void> initialize() async {
    try {
      // Initialize notification service
      await _notificationService.init();

      // Request notification permissions
      await _notificationService.requestPermissions();

      // Load tasks
      await loadTasks();

      // Refresh all notifications when app first starts
      await _dbService.refreshAllNotifications();
    } catch (e) {
      debugPrint('Error initializing TaskProvider: $e');
    }
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      notifyListeners();

      _allTasks = _dbService.getAllTasks();
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Apply current filters
  void _applyFilters() {
    _filteredTasks = _allTasks;

    // Apply date filter
    if (_isDateFiltered && _selectedDate != null) {
      _filteredTasks = _dbService.getTasksByDate(_selectedDate!);
    }

    // Apply workspace filter
    if (_selectedWorkspace.isNotEmpty) {
      _filteredTasks =
          _filteredTasks
              .where(
                (task) =>
                    task.workspace?.toLowerCase() ==
                    _selectedWorkspace.toLowerCase(),
              )
              .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredTasks =
          _filteredTasks.where((task) {
            return task.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                task.subtasks.any(
                  (subtask) => subtask.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                );
          }).toList();
    }
  }

  /// Add new task
  Future<void> addTask(Task task) async {
    try {
      await _dbService.addTask(task);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing task
  Future<void> updateTask(int key, Task updatedTask) async {
    try {
      await _dbService.updateTask(key, updatedTask);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(int key) async {
    try {
      await _dbService.deleteTask(key);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle main task completion
  Future<void> toggleMainTaskCompletion(int key) async {
    try {
      await _dbService.toggleMainTaskCompletion(key);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle subtask completion
  Future<void> toggleSubtaskCompletion(int key, int subtaskIndex) async {
    try {
      await _dbService.toggleSubtaskCompletion(key, subtaskIndex);
      await loadTasks();
    } catch (e) {
      rethrow;
    }
  }

  /// Get task key by matching task properties
  int? getTaskKey(Task task) {
    final box = _dbService.tasksBox;
    for (var key in box.keys) {
      final boxTask = box.get(key);
      if (boxTask != null &&
          boxTask.title == task.title &&
          boxTask.date == task.date &&
          boxTask.time == task.time) {
        return key as int;
      }
    }
    return null;
  }

  /// Get tasks by date
  List<Task> getTasksByDate(DateTime date) {
    return _dbService.getTasksByDate(date);
  }

  /// Get today's tasks
  List<Task> getTodayTasks() {
    return _dbService.getTodayTasks();
  }

  /// Get upcoming tasks
  List<Task> getUpcomingTasks() {
    return _dbService.getUpcomingTasks();
  }

  /// Get completed tasks
  List<Task> getCompletedTasks() {
    return _dbService.getCompletedTasks();
  }

  /// Get tasks by workspace
  List<Task> getTasksByWorkspace(String workspace) {
    return _dbService.getTasksByWorkspace(workspace);
  }

  /// Get all workspaces
  List<String> getAllWorkspaces() {
    return _dbService.getAllWorkspaces();
  }

  /// Set date filter
  void setDateFilter(DateTime date) {
    _selectedDate = date;
    _isDateFiltered = true;
    _applyFilters();
    notifyListeners();
  }

  /// Clear date filter
  void clearDateFilter() {
    _selectedDate = DateTime.now();
    _isDateFiltered = false;
    _applyFilters();
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set workspace filter
  void setWorkspaceFilter(String workspace) {
    _selectedWorkspace = workspace;
    _applyFilters();
    notifyListeners();
  }

  /// Clear workspace filter
  void clearWorkspaceFilter() {
    _selectedWorkspace = '';
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    _selectedDate = DateTime.now();
    _isDateFiltered = false;
    _searchQuery = '';
    _selectedWorkspace = '';
    _applyFilters();
    notifyListeners();
  }

  /// Get task statistics
  Map<String, int> getTaskStats() {
    final total = _allTasks.length;
    final completed = getCompletedTasks().length;
    final pending = total - completed;

    return {'total': total, 'completed': completed, 'pending': pending};
  }

  /// Get workspace statistics
  Map<String, int> getWorkspaceStats(String workspace) {
    final tasks = getTasksByWorkspace(workspace);
    final completed =
        tasks
            .where(
              (task) => task.isMainTaskCompleted || task.allSubtasksCompleted,
            )
            .length;

    return {
      'total': tasks.length,
      'completed': completed,
      'pending': tasks.length - completed,
    };
  }

  /// Get notification debug info
  Future<Map<String, dynamic>> getNotificationDebugInfo() async {
    return await _notificationService.getNotificationDebugInfo();
  }

  /// Manually refresh all notifications
  Future<void> refreshNotifications() async {
    try {
      await _dbService.refreshAllNotifications();
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }
}
