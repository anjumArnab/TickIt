import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '/models/sqflite/task.dart';
import '../../models/sqflite/subtask.dart';

class DBService {
  static const String _databaseName = 'tasks.db';
  static const int _databaseVersion = 1;

  static const String tableTask = 'tasks';
  static const String tableSubtask = 'subtasks';

  static Database? _database;

  // Private constructor for singleton pattern
  DBService._();
  static final DBService _instance = DBService._();
  static DBService get instance => _instance;

  /// Initialize the database
  static Future<void> init() async {
    if (_database != null) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE $tableTask (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        isMainTaskCompleted INTEGER NOT NULL DEFAULT 0,
        flagColorValue INTEGER NOT NULL,
        date TEXT NOT NULL,
        workspace TEXT,
        workspaceColorValue INTEGER
      )
    ''');

    // Create subtasks table with foreign key
    await db.execute('''
      CREATE TABLE $tableSubtask (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (taskId) REFERENCES $tableTask (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Get the database instance
  Database get database {
    if (_database == null) {
      throw Exception(
        'DBService not initialized. Call DBService.init() first.',
      );
    }
    return _database!;
  }


  /// Add a new task with subtasks
  Future<int> addTask(Task task) async {
    try {
      final db = database;
      
      // Insert task and get the generated id
      final taskId = await db.insert(tableTask, task.toMap());
      
      // Insert subtasks with the task id
      for (final subtask in task.subtasks) {
        subtask.taskId = taskId;
        await db.insert(tableSubtask, subtask.toMap());
      }
      
      return taskId;
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  /// Get all tasks with subtasks
  Future<List<Task>> getAllTasks() async {
    try {
      final db = database;
      final List<Map<String, dynamic>> taskMaps = await db.query(tableTask);
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get all tasks: $e');
    }
  }

  /// Get subtasks for a specific task
  Future<List<Subtask>> _getSubtasksForTask(int taskId) async {
    final db = database;
    final List<Map<String, dynamic>> subtaskMaps = await db.query(
      tableSubtask,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    
    return subtaskMaps.map((map) => Subtask.fromMap(map)).toList();
  }

  /// Get task by id
  Future<Task?> getTask(int id) async {
    try {
      final db = database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableTask,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      
      final subtasks = await _getSubtasksForTask(id);
      return Task.fromMap(maps.first, subtasks: subtasks);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  /// Get tasks by date
  Future<List<Task>> getTasksByDate(DateTime date) async {
    try {
      final db = database;
      final dateOnly = DateTime(date.year, date.month, date.day);
      final dateStr = dateOnly.toIso8601String().split('T')[0];
      
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'date LIKE ?',
        whereArgs: ['$dateStr%'],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  /// Get today's tasks
  Future<List<Task>> getTodayTasks() async {
    return getTasksByDate(DateTime.now());
  }

  /// Get upcoming tasks (after today)
  Future<List<Task>> getUpcomingTasks() async {
    try {
      final db = database;
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final todayStr = todayOnly.toIso8601String();
      
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'date > ?',
        whereArgs: [todayStr],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get upcoming tasks: $e');
    }
  }

  /// Get tasks by workspace
  Future<List<Task>> getTasksByWorkspace(String workspace) async {
    try {
      final db = database;
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'LOWER(workspace) = ?',
        whereArgs: [workspace.toLowerCase()],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by workspace: $e');
    }
  }

  /// Get completed tasks (main task completed OR all subtasks completed)
  Future<List<Task>> getCompletedTasks() async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.where((task) {
        return task.isMainTaskCompleted || task.allSubtasksCompleted;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get completed tasks: $e');
    }
  }

  /// Get tasks with completed main task only
  Future<List<Task>> getMainTaskCompletedTasks() async {
    try {
      final db = database;
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'isMainTaskCompleted = ?',
        whereArgs: [1],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get main task completed tasks: $e');
    }
  }

  /// Get tasks with all subtasks completed
  Future<List<Task>> getAllSubtasksCompletedTasks() async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.where((task) => task.allSubtasksCompleted).toList();
    } catch (e) {
      throw Exception('Failed to get all subtasks completed tasks: $e');
    }
  }

  /// Get tasks grouped by date
  Future<Map<DateTime, List<Task>>> getTasksGroupedByDate() async {
    try {
      final allTasks = await getAllTasks();
      final Map<DateTime, List<Task>> groupedTasks = {};

      for (Task task in allTasks) {
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
  Future<void> updateTask(Task task) async {
    try {
      if (task.id == null) {
        throw Exception('Task id cannot be null for update');
      }

      final db = database;
      
      // Update task
      await db.update(
        tableTask,
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      
      // Delete existing subtasks
      await db.delete(
        tableSubtask,
        where: 'taskId = ?',
        whereArgs: [task.id],
      );
      
      // Insert new subtasks
      for (final subtask in task.subtasks) {
        subtask.taskId = task.id;
        await db.insert(tableSubtask, subtask.toMap());
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Toggle main task completion
  Future<void> toggleMainTaskCompletion(int id) async {
    try {
      final task = await getTask(id);
      if (task != null) {
        task.isMainTaskCompleted = !task.isMainTaskCompleted;
        await database.update(
          tableTask,
          {'isMainTaskCompleted': task.isMainTaskCompleted ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to toggle main task completion: $e');
    }
  }

  /// Set main task completion status
  Future<void> setMainTaskCompletion(int id, bool isCompleted) async {
    try {
      final db = database;
      await db.update(
        tableTask,
        {'isMainTaskCompleted': isCompleted ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to set main task completion: $e');
    }
  }

  /// Toggle subtask completion
  Future<void> toggleSubtaskCompletion(int taskId, int subtaskId) async {
    try {
      final db = database;
      final subtaskMaps = await db.query(
        tableSubtask,
        where: 'id = ? AND taskId = ?',
        whereArgs: [subtaskId, taskId],
      );
      
      if (subtaskMaps.isEmpty) {
        throw Exception('Subtask not found');
      }
      
      final subtask = Subtask.fromMap(subtaskMaps.first);
      subtask.isCompleted = !subtask.isCompleted;
      
      await db.update(
        tableSubtask,
        {'isCompleted': subtask.isCompleted ? 1 : 0},
        where: 'id = ?',
        whereArgs: [subtaskId],
      );
    } catch (e) {
      throw Exception('Failed to toggle subtask completion: $e');
    }
  }

  /// Set subtask completion status
  Future<void> setSubtaskCompletion(
    int taskId,
    int subtaskId,
    bool isCompleted,
  ) async {
    try {
      final db = database;
      await db.update(
        tableSubtask,
        {'isCompleted': isCompleted ? 1 : 0},
        where: 'id = ? AND taskId = ?',
        whereArgs: [subtaskId, taskId],
      );
    } catch (e) {
      throw Exception('Failed to set subtask completion: $e');
    }
  }

  /// Add subtask to existing task
  Future<void> addSubtask(int taskId, Subtask subtask) async {
    try {
      final db = database;
      subtask.taskId = taskId;
      await db.insert(tableSubtask, subtask.toMap());
    } catch (e) {
      throw Exception('Failed to add subtask: $e');
    }
  }

  /// Remove subtask from existing task
  Future<void> removeSubtask(int subtaskId) async {
    try {
      final db = database;
      await db.delete(
        tableSubtask,
        where: 'id = ?',
        whereArgs: [subtaskId],
      );
    } catch (e) {
      throw Exception('Failed to remove subtask: $e');
    }
  }

  /// Update subtask title
  Future<void> updateSubtaskTitle(int subtaskId, String newTitle) async {
    try {
      final db = database;
      await db.update(
        tableSubtask,
        {'title': newTitle},
        where: 'id = ?',
        whereArgs: [subtaskId],
      );
    } catch (e) {
      throw Exception('Failed to update subtask title: $e');
    }
  }

  /// Delete a task by id (subtasks will be deleted automatically due to foreign key)
  Future<void> deleteTask(int id) async {
    try {
      final db = database;
      await db.delete(
        tableTask,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }


  /// Get task count
  Future<int> getTaskCount() async {
    final db = database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableTask');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get task count by date
  Future<int> getTaskCountByDate(DateTime date) async {
    final tasks = await getTasksByDate(date);
    return tasks.length;
  }

  /// Get completed task count
  Future<int> getCompletedTaskCount() async {
    final tasks = await getCompletedTasks();
    return tasks.length;
  }

  /// Get completed task count by date
  Future<int> getCompletedTaskCountByDate(DateTime date) async {
    final tasks = await getTasksByDate(date);
    return tasks
        .where((task) => task.isMainTaskCompleted || task.allSubtasksCompleted)
        .length;
  }

  /// Get all unique workspaces
  Future<List<String>> getAllWorkspaces() async {
    try {
      final db = database;
      final result = await db.rawQuery(
        'SELECT DISTINCT workspace FROM $tableTask WHERE workspace IS NOT NULL AND workspace != "" ORDER BY workspace',
      );
      
      return result
          .map((row) => row['workspace'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get workspaces: $e');
    }
  }

  /// Search tasks by title
  Future<List<Task>> searchTasks(String query) async {
    try {
      if (query.isEmpty) return getAllTasks();

      final db = database;
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'LOWER(title) LIKE ?',
        whereArgs: ['%${query.toLowerCase()}%'],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  /// Search tasks by title and subtask titles
  Future<List<Task>> searchTasksAndSubtasks(String query) async {
    try {
      if (query.isEmpty) return getAllTasks();

      final db = database;
      
      // Search in main task titles
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'LOWER(title) LIKE ?',
        whereArgs: ['%${query.toLowerCase()}%'],
      );
      
      // Search in subtask titles
      final List<Map<String, dynamic>> subtaskMaps = await db.query(
        tableSubtask,
        where: 'LOWER(title) LIKE ?',
        whereArgs: ['%${query.toLowerCase()}%'],
      );
      
      Set<int> taskIds = {};
      
      // Add task ids from main search
      for (final taskMap in taskMaps) {
        taskIds.add(taskMap['id'] as int);
      }
      
      // Add task ids from subtask search
      for (final subtaskMap in subtaskMaps) {
        taskIds.add(subtaskMap['taskId'] as int);
      }
      
      // Get all matching tasks
      List<Task> tasks = [];
      for (final id in taskIds) {
        final task = await getTask(id);
        if (task != null) {
          tasks.add(task);
        }
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to search tasks and subtasks: $e');
    }
  }

  /// Get tasks within date range
  Future<List<Task>> getTasksInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = database;
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks in date range: $e');
    }
  }

  /// Get tasks by workspace color
  Future<List<Task>> getTasksByWorkspaceColor(int colorValue) async {
    try {
      final db = database;
      final List<Map<String, dynamic>> taskMaps = await db.query(
        tableTask,
        where: 'workspaceColorValue = ?',
        whereArgs: [colorValue],
      );
      
      List<Task> tasks = [];
      for (final taskMap in taskMaps) {
        final subtasks = await _getSubtasksForTask(taskMap['id'] as int);
        tasks.add(Task.fromMap(taskMap, subtasks: subtasks));
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to get tasks by workspace color: $e');
    }
  }

}