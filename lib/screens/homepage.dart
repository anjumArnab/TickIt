import 'package:flutter/material.dart';
import '../models/hive/task.dart';
import '../screens/app_drawer.dart';
import '../screens/taskpage.dart';
import '../services/hive/db_service.dart';
import '../widgets/expanded_calendar.dart';
import '../widgets/date_task_card.dart';
import '../widgets/task_group.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDay;
  bool _showCalendar = false;
  bool _isDateFiltered = false;

  final DBService _dbService = DBService.instance;
  List<Task> _allTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final tasks = _dbService.getAllTasks();

      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshTasks() {
    _loadTasks();
  }

  void _closeCalendar() {
    if (_showCalendar) {
      setState(() {
        _showCalendar = false;
      });
    }
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDay = selectedDate;
      _isDateFiltered = true;
      _showCalendar = false;
    });
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDay = DateTime.now();
      _isDateFiltered = false;
    });
  }

  int? _getTaskKey(Task task) {
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

  Future<void> _toggleMainTaskCompletion(Task task) async {
    final taskKey = _getTaskKey(task);
    if (taskKey != null) {
      try {
        await _dbService.toggleMainTaskCompletion(taskKey);
        _refreshTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleSubtaskCompletion(Task task, int subtaskIndex) async {
    final taskKey = _getTaskKey(task);
    if (taskKey != null) {
      try {
        await _dbService.toggleSubtaskCompletion(taskKey, subtaskIndex);
        _refreshTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating subtask: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navToTaskPageForEdit(BuildContext context, Task task) async {
    final taskKey = _getTaskKey(task);

    if (taskKey != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskPage(task: task, taskKey: taskKey),
        ),
      );

      if (result != null) {
        _refreshTasks();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Task not found for editing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getColorFromValue(int colorValue) {
    return Color(colorValue);
  }

  void _navToTaskPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskPage()),
    );

    if (result != null) {
      _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tick It',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCalendar ? Icons.calendar_today : Icons.calendar_month,
              color: _showCalendar ? Colors.blue : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshTasks,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: GestureDetector(
        onTap: _closeCalendar,
        child: Column(
          children: [
            if (_isDateFiltered)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blue[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Showing tasks for: ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  _closeCalendar();
                },
                tabs: const [
                  Tab(text: 'All todos'),
                  Tab(text: 'Today'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                ],
                labelColor: Colors.blue[800],
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.blue[800],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllTodosTab(),
                          _buildTodayTab(),
                          _buildUpcomingTab(),
                          _buildCompletedTab(),
                        ],
                      ),
            ),
            if (_showCalendar)
              ExpandedCalendar(
                selectedDay: _selectedDay,
                onDateSelected: _onDateSelected,
              ),
          ],
        ),
      ),
      floatingActionButton:
          _showCalendar
              ? null
              : FloatingActionButton(
                backgroundColor: Colors.green,
                shape: const CircleBorder(),
                onPressed: () => _navToTaskPage(context),
                child: const Icon(Icons.add, color: Colors.white),
              ),
    );
  }

  Widget _buildAllTodosTab() {
    List<Task> tasksToDisplay =
        _isDateFiltered ? _dbService.getTasksByDate(_selectedDay!) : _allTasks;

    if (tasksToDisplay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isDateFiltered ? 'No tasks for this date' : 'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isDateFiltered
                  ? 'Try selecting a different date'
                  : 'Tap + to create your first task',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_isDateFiltered) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children:
                    tasksToDisplay.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TaskGroup(
                          title: task.title,
                          time: task.time,
                          progress: task.progress,
                          flagColor: _getColorFromValue(task.flagColorValue),
                          subtasks: task.subtasks.map((s) => s.title).toList(),
                          workspace: task.workspace,
                          workspaceColor:
                              task.workspaceColorValue != null
                                  ? _getColorFromValue(
                                    task.workspaceColorValue!,
                                  )
                                  : null,
                          isMainTaskCompleted: task.isMainTaskCompleted,
                          subtaskCompletionStates:
                              task.subtasks.map((s) => s.isCompleted).toList(),
                          onMainTaskToggle:
                              () => _toggleMainTaskCompletion(task),
                          onSubtaskToggle:
                              (index) => _toggleSubtaskCompletion(task, index),
                          onTap: () => _navToTaskPageForEdit(context, task),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    Map<DateTime, List<Task>> groupedTasks = {};
    for (Task task in tasksToDisplay) {
      DateTime dateOnly = DateTime(
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

    List<DateTime> sortedDates =
        groupedTasks.keys.toList()..sort((a, b) => a.compareTo(b));

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          ...sortedDates.map((date) {
            List<Task> tasksForDate = groupedTasks[date]!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DateTaskCard(
                    date: date,
                    taskCount: tasksForDate.length,
                    onTap: () {
                      setState(() {
                        _selectedDay = date;
                        _isDateFiltered = true;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ...tasksForDate.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskGroup(
                        title: task.title,
                        time: task.time,
                        progress: task.progress,
                        flagColor: _getColorFromValue(task.flagColorValue),
                        subtasks: task.subtasks.map((s) => s.title).toList(),
                        workspace: task.workspace,
                        workspaceColor:
                            task.workspaceColorValue != null
                                ? _getColorFromValue(task.workspaceColorValue!)
                                : null,
                        isMainTaskCompleted: task.isMainTaskCompleted,
                        subtaskCompletionStates:
                            task.subtasks.map((s) => s.isCompleted).toList(),
                        onMainTaskToggle: () => _toggleMainTaskCompletion(task),
                        onSubtaskToggle:
                            (index) => _toggleSubtaskCompletion(task, index),
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    List<Task> todayTasks = _dbService.getTodayTasks();

    if (todayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks for today',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children:
                  todayTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskGroup(
                        title: task.title,
                        time: task.time,
                        progress: task.progress,
                        flagColor: _getColorFromValue(task.flagColorValue),
                        subtasks: task.subtasks.map((s) => s.title).toList(),
                        workspace: task.workspace,
                        workspaceColor:
                            task.workspaceColorValue != null
                                ? _getColorFromValue(task.workspaceColorValue!)
                                : null,
                        isMainTaskCompleted: task.isMainTaskCompleted,
                        subtaskCompletionStates:
                            task.subtasks.map((s) => s.isCompleted).toList(),
                        onMainTaskToggle: () => _toggleMainTaskCompletion(task),
                        onSubtaskToggle:
                            (index) => _toggleSubtaskCompletion(task, index),
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    List<Task> upcomingTasks = _dbService.getUpcomingTasks();

    if (upcomingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No upcoming tasks',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children:
                  upcomingTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskGroup(
                        title: task.title,
                        time: task.time,
                        progress: task.progress,
                        flagColor: _getColorFromValue(task.flagColorValue),
                        subtasks: task.subtasks.map((s) => s.title).toList(),
                        workspace: task.workspace,
                        workspaceColor:
                            task.workspaceColorValue != null
                                ? _getColorFromValue(task.workspaceColorValue!)
                                : null,
                        isMainTaskCompleted: task.isMainTaskCompleted,
                        subtaskCompletionStates:
                            task.subtasks.map((s) => s.isCompleted).toList(),
                        onMainTaskToggle: () => _toggleMainTaskCompletion(task),
                        onSubtaskToggle:
                            (index) => _toggleSubtaskCompletion(task, index),
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    List<Task> completedTasks = _dbService.getCompletedTasks();

    if (completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No completed tasks',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children:
                  completedTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskGroup(
                        title: task.title,
                        time: task.time,
                        progress: task.progress,
                        flagColor: _getColorFromValue(task.flagColorValue),
                        subtasks: task.subtasks.map((s) => s.title).toList(),
                        workspace: task.workspace,
                        workspaceColor:
                            task.workspaceColorValue != null
                                ? _getColorFromValue(task.workspaceColorValue!)
                                : null,
                        isMainTaskCompleted: task.isMainTaskCompleted,
                        subtaskCompletionStates:
                            task.subtasks.map((s) => s.isCompleted).toList(),
                        onMainTaskToggle: () => _toggleMainTaskCompletion(task),
                        onSubtaskToggle:
                            (index) => _toggleSubtaskCompletion(task, index),
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
