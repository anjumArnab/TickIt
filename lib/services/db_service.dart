import 'package:hive_flutter/hive_flutter.dart';
import '../model/task.dart';

class DBService {
  static const String _boxName = 'tasks';
  static Box<Task>? _box;

  // Private constructor for singleton pattern
  DBService._();
  static final DBService _instance = DBService._();
  static DBService get instance => _instance;

  /// Initialize Hive and open the tasks box
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register the Task adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }

    // Open the tasks box
    _box = await Hive.openBox<Task>(_boxName);
  }

  /// Get the tasks box, throw error if not initialized
  Box<Task> get _tasksBox {
    if (_box == null) {
      throw Exception(
        'DBService not initialized. Call DBService.init() first.',
      );
    }
    return _box!;
  }

  // CRUD Operations

  /// Create - Add a new task
  Future<void> addTask(Task task) async {
    try {
      await _tasksBox.add(task);
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  /// Read - Get all tasks
  List<Task> getAllTasks() {
    try {
      return _tasksBox.values.toList();
    } catch (e) {
      throw Exception('Failed to get all tasks: $e');
    }
  }

  /// Read - Get task by key
  Task? getTask(int key) {
    try {
      return _tasksBox.get(key);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  /// Read - Get tasks by date
  List<Task> getTasksByDate(DateTime date) {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      return _tasksBox.values.where((task) {
        final taskDate = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );
        return taskDate == dateOnly;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  /// Read - Get today's tasks
  List<Task> getTodayTasks() {
    return getTasksByDate(DateTime.now());
  }

  /// Read - Get upcoming tasks (after today)
  List<Task> getUpcomingTasks() {
    try {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      return _tasksBox.values.where((task) {
        final taskDate = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );
        return taskDate.isAfter(todayOnly);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get upcoming tasks: $e');
    }
  }

  /// Read - Get tasks by workspace
  List<Task> getTasksByWorkspace(String workspace) {
    try {
      return _tasksBox.values
          .where(
            (task) => task.workspace?.toLowerCase() == workspace.toLowerCase(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks by workspace: $e');
    }
  }

  /// Read - Get completed tasks (assuming progress like "5/5" means completed)
  List<Task> getCompletedTasks() {
    try {
      return _tasksBox.values.where((task) {
        final progressParts = task.progress.split('/');
        if (progressParts.length == 2) {
          final completed = int.tryParse(progressParts[0]) ?? 0;
          final total = int.tryParse(progressParts[1]) ?? 1;
          return completed >= total;
        }
        return false;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get completed tasks: $e');
    }
  }

  /// Read - Get tasks grouped by date
  Map<DateTime, List<Task>> getTasksGroupedByDate() {
    try {
      final Map<DateTime, List<Task>> groupedTasks = {};

      for (Task task in _tasksBox.values) {
        final dateOnly = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );

        if (groupedTasks.containsKey(dateOnly)) {
          groupedTasks[dateOnly]!.add(task);
        } else {
          groupedTasks[dateOnly] = [task];
        }
      }

      return groupedTasks;
    } catch (e) {
      throw Exception('Failed to group tasks by date: $e');
    }
  }

  /// Update - Update an existing task
  Future<void> updateTask(int key, Task updatedTask) async {
    try {
      await _tasksBox.put(key, updatedTask);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Update - Update task progress
  Future<void> updateTaskProgress(int key, String newProgress) async {
    try {
      final task = _tasksBox.get(key);
      if (task != null) {
        task.progress = newProgress;
        await task.save();
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to update task progress: $e');
    }
  }

  /// Update - Toggle subtask completion
  Future<void> toggleSubtaskCompletion(int taskKey, int subtaskIndex) async {
    try {
      final task = _tasksBox.get(taskKey);
      if (task != null && subtaskIndex < task.subtasks.length) {
        // This is a simple implementation - you might want to track completed subtasks differently
        final progressParts = task.progress.split('/');
        if (progressParts.length == 2) {
          int completed = int.tryParse(progressParts[0]) ?? 0;
          final total = int.tryParse(progressParts[1]) ?? task.subtasks.length;

          // Toggle completion (this is simplified - you'd need better tracking)
          completed = completed < total ? completed + 1 : completed - 1;
          completed = completed.clamp(0, total);

          task.progress = '$completed/$total';
          await task.save();
        }
      } else {
        throw Exception('Task or subtask not found');
      }
    } catch (e) {
      throw Exception('Failed to toggle subtask completion: $e');
    }
  }

  /// Delete - Delete a task by key
  Future<void> deleteTask(int key) async {
    try {
      await _tasksBox.delete(key);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Delete - Delete multiple tasks
  Future<void> deleteTasks(List<int> keys) async {
    try {
      await _tasksBox.deleteAll(keys);
    } catch (e) {
      throw Exception('Failed to delete tasks: $e');
    }
  }

  /// Delete - Clear all tasks
  Future<void> clearAllTasks() async {
    try {
      await _tasksBox.clear();
    } catch (e) {
      throw Exception('Failed to clear all tasks: $e');
    }
  }

  /// Utility - Get task count
  int getTaskCount() {
    return _tasksBox.length;
  }

  /// Utility - Get task count by date
  int getTaskCountByDate(DateTime date) {
    return getTasksByDate(date).length;
  }

  /// Utility - Get all unique workspaces
  List<String> getAllWorkspaces() {
    try {
      final workspaces = <String>{};
      for (final task in _tasksBox.values) {
        if (task.workspace != null && task.workspace!.isNotEmpty) {
          workspaces.add(task.workspace!);
        }
      }
      return workspaces.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get workspaces: $e');
    }
  }

  /// Utility - Search tasks by title
  List<Task> searchTasks(String query) {
    try {
      if (query.isEmpty) return getAllTasks();

      return _tasksBox.values
          .where(
            (task) => task.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  /// Utility - Get tasks within date range
  List<Task> getTasksInDateRange(DateTime startDate, DateTime endDate) {
    try {
      return _tasksBox.values.where((task) {
        final taskDate = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);

        return taskDate.isAtSameMomentAs(start) ||
            taskDate.isAtSameMomentAs(end) ||
            (taskDate.isAfter(start) && taskDate.isBefore(end));
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks in date range: $e');
    }
  }

  /// Listen to box changes
  Stream<BoxEvent> watchTasks() {
    return _tasksBox.watch();
  }

  /// Close the database
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Compact the database (optional - for performance)
  Future<void> compact() async {
    try {
      await _tasksBox.compact();
    } catch (e) {
      throw Exception('Failed to compact database: $e');
    }
  }
}
