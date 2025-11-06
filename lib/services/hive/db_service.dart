import 'package:hive_flutter/hive_flutter.dart';
import '../../models/hive/task.dart';

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

    // Register the Subtask adapter if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SubtaskAdapter());
    }

    // Open the tasks box
    _box = await Hive.openBox<Task>(_boxName);
  }

  /// Get the tasks box, throw error if not initialized
  Box<Task> get tasksBox {
    if (_box == null) {
      throw Exception(
        'DBService not initialized. Call DBService.init() first.',
      );
    }
    return _box!;
  }


  /// Add a new task
  Future<void> addTask(Task task) async {
    try {
      await tasksBox.add(task);
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  /// Get all tasks
  List<Task> getAllTasks() {
    try {
      return tasksBox.values.toList();
    } catch (e) {
      throw Exception('Failed to get all tasks: $e');
    }
  }

  /// Get task by key
  Task? getTask(int key) {
    try {
      return tasksBox.get(key);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  /// Get tasks by date
  List<Task> getTasksByDate(DateTime date) {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      return tasksBox.values.where((task) {
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

  /// Get today's tasks
  List<Task> getTodayTasks() {
    return getTasksByDate(DateTime.now());
  }

  /// Get upcoming tasks (after today)
  List<Task> getUpcomingTasks() {
    try {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      return tasksBox.values.where((task) {
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

  /// Get tasks by workspace
  List<Task> getTasksByWorkspace(String workspace) {
    try {
      return tasksBox.values
          .where(
            (task) => task.workspace?.toLowerCase() == workspace.toLowerCase(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks by workspace: $e');
    }
  }

  /// Get completed tasks (main task completed OR all subtasks completed)
  List<Task> getCompletedTasks() {
    try {
      return tasksBox.values.where((task) {
        return task.isMainTaskCompleted || task.allSubtasksCompleted;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get completed tasks: $e');
    }
  }

  /// Get tasks with completed main task only
  List<Task> getMainTaskCompletedTasks() {
    try {
      return tasksBox.values.where((task) => task.isMainTaskCompleted).toList();
    } catch (e) {
      throw Exception('Failed to get main task completed tasks: $e');
    }
  }

  /// Get tasks with all subtasks completed
  List<Task> getAllSubtasksCompletedTasks() {
    try {
      return tasksBox.values
          .where((task) => task.allSubtasksCompleted)
          .toList();
    } catch (e) {
      throw Exception('Failed to get all subtasks completed tasks: $e');
    }
  }

  /// Get tasks grouped by date
  Map<DateTime, List<Task>> getTasksGroupedByDate() {
    try {
      final Map<DateTime, List<Task>> groupedTasks = {};

      for (Task task in tasksBox.values) {
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

  /// Update an existing task
  Future<void> updateTask(int key, Task updatedTask) async {
    try {
      await tasksBox.put(key, updatedTask);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Toggle main task completion
  Future<void> toggleMainTaskCompletion(int key) async {
    try {
      final task = tasksBox.get(key);
      if (task != null) {
        task.isMainTaskCompleted = !task.isMainTaskCompleted;
        await task.save();
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to toggle main task completion: $e');
    }
  }

  /// Set main task completion status
  Future<void> setMainTaskCompletion(int key, bool isCompleted) async {
    try {
      final task = tasksBox.get(key);
      if (task != null) {
        task.isMainTaskCompleted = isCompleted;
        await task.save();
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to set main task completion: $e');
    }
  }

  /// Toggle subtask completion
  Future<void> toggleSubtaskCompletion(int taskKey, int subtaskIndex) async {
    try {
      final task = tasksBox.get(taskKey);
      if (task != null && subtaskIndex < task.subtasks.length) {
        task.subtasks[subtaskIndex].isCompleted =
            !task.subtasks[subtaskIndex].isCompleted;
        await task.save();
      } else {
        throw Exception('Task or subtask not found');
      }
    } catch (e) {
      throw Exception('Failed to toggle subtask completion: $e');
    }
  }

  /// Set subtask completion status
  Future<void> setSubtaskCompletion(
    int taskKey,
    int subtaskIndex,
    bool isCompleted,
  ) async {
    try {
      final task = tasksBox.get(taskKey);
      if (task != null && subtaskIndex < task.subtasks.length) {
        task.subtasks[subtaskIndex].isCompleted = isCompleted;
        await task.save();
      } else {
        throw Exception('Task or subtask not found');
      }
    } catch (e) {
      throw Exception('Failed to set subtask completion: $e');
    }
  }

  /// Add subtask to existing task
  Future<void> addSubtask(int taskKey, Subtask subtask) async {
    try {
      final task = tasksBox.get(taskKey);
      if (task != null) {
        task.subtasks.add(subtask);
        await task.save();
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to add subtask: $e');
    }
  }

  /// Remove subtask from existing task
  Future<void> removeSubtask(int taskKey, int subtaskIndex) async {
    try {
      final task = tasksBox.get(taskKey);
      if (task != null && subtaskIndex < task.subtasks.length) {
        task.subtasks.removeAt(subtaskIndex);
        await task.save();
      } else {
        throw Exception('Task or subtask not found');
      }
    } catch (e) {
      throw Exception('Failed to remove subtask: $e');
    }
  }

  /// Update subtask title
  Future<void> updateSubtaskTitle(
    int taskKey,
    int subtaskIndex,
    String newTitle,
  ) async {
    try {
      final task = tasksBox.get(taskKey);
      if (task != null && subtaskIndex < task.subtasks.length) {
        task.subtasks[subtaskIndex].title = newTitle;
        await task.save();
      } else {
        throw Exception('Task or subtask not found');
      }
    } catch (e) {
      throw Exception('Failed to update subtask title: $e');
    }
  }

  /// Delete a task by key
  Future<void> deleteTask(int key) async {
    try {
      await tasksBox.delete(key);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Delete multiple tasks
  Future<void> deleteTasks(List<int> keys) async {
    try {
      await tasksBox.deleteAll(keys);
    } catch (e) {
      throw Exception('Failed to delete tasks: $e');
    }
  }

  /// Clear all tasks
  Future<void> clearAllTasks() async {
    try {
      await tasksBox.clear();
    } catch (e) {
      throw Exception('Failed to clear all tasks: $e');
    }
  }

  /// Get task count
  int getTaskCount() {
    return tasksBox.length;
  }

  /// Get task count by date
  int getTaskCountByDate(DateTime date) {
    return getTasksByDate(date).length;
  }

  /// Get completed task count
  int getCompletedTaskCount() {
    return getCompletedTasks().length;
  }

  /// Get completed task count by date
  int getCompletedTaskCountByDate(DateTime date) {
    return getTasksByDate(date)
        .where((task) => task.isMainTaskCompleted || task.allSubtasksCompleted)
        .length;
  }

  /// Get all unique workspaces
  List<String> getAllWorkspaces() {
    try {
      final workspaces = <String>{};
      for (final task in tasksBox.values) {
        if (task.workspace != null && task.workspace!.isNotEmpty) {
          workspaces.add(task.workspace!);
        }
      }
      return workspaces.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get workspaces: $e');
    }
  }

  /// Search tasks by title
  List<Task> searchTasks(String query) {
    try {
      if (query.isEmpty) return getAllTasks();

      return tasksBox.values
          .where(
            (task) => task.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  /// Search tasks by title and subtask titles
  List<Task> searchTasksAndSubtasks(String query) {
    try {
      if (query.isEmpty) return getAllTasks();

      return tasksBox.values.where((task) {
        // Search in main task title
        if (task.title.toLowerCase().contains(query.toLowerCase())) {
          return true;
        }

        // Search in subtask titles
        return task.subtasks.any(
          (subtask) =>
              subtask.title.toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tasks and subtasks: $e');
    }
  }

  /// Get tasks within date range
  List<Task> getTasksInDateRange(DateTime startDate, DateTime endDate) {
    try {
      return tasksBox.values.where((task) {
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

  /// Get tasks by workspace color
  List<Task> getTasksByWorkspaceColor(int colorValue) {
    try {
      return tasksBox.values
          .where((task) => task.workspaceColorValue == colorValue)
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks by workspace color: $e');
    }
  }
}
