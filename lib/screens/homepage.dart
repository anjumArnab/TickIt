import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hive/task.dart';
import '../widgets/app_drawer.dart';
import '../screens/taskpage.dart';
import '../widgets/expanded_calendar.dart';
import '../widgets/date_task_card.dart';
import '../widgets/task_group.dart';
import '../providers/task_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDay = DateTime.now();

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _closeCalendar() {
    if (_showCalendar) {
      setState(() {
        _showCalendar = false;
      });
    }
  }

  void _onDateSelected(DateTime selectedDate) {
    context.read<TaskProvider>().setDateFilter(selectedDate);
    setState(() {
      _selectedDay = selectedDate;
      _showCalendar = false;
    });
  }

  void _clearDateFilter() {
    context.read<TaskProvider>().clearDateFilter();
    setState(() {
      _selectedDay = DateTime.now();
    });
  }

  Future<void> _toggleMainTaskCompletion(Task task) async {
    final provider = context.read<TaskProvider>();
    final taskKey = provider.getTaskKey(task);

    if (taskKey != null) {
      try {
        await provider.toggleMainTaskCompletion(taskKey);
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
    final provider = context.read<TaskProvider>();
    final taskKey = provider.getTaskKey(task);

    if (taskKey != null) {
      try {
        await provider.toggleSubtaskCompletion(taskKey, subtaskIndex);
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
    final provider = context.read<TaskProvider>();
    final taskKey = provider.getTaskKey(task);

    if (taskKey != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskPage(task: task, taskKey: taskKey),
        ),
      );

      if (result != null) {
        // Provider will auto-update via notifyListeners
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
      MaterialPageRoute(builder: (context) => const TaskPage()),
    );

    if (result != null) {
      // Provider will auto-update via notifyListeners
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
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
                onPressed: () => taskProvider.loadTasks(),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: GestureDetector(
            onTap: _closeCalendar,
            child: Column(
              children: [
                if (taskProvider.isDateFiltered)
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
                      taskProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAllTodosTab(taskProvider),
                              _buildTodayTab(taskProvider),
                              _buildUpcomingTab(taskProvider),
                              _buildCompletedTab(taskProvider),
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
      },
    );
  }

  Widget _buildAllTodosTab(TaskProvider taskProvider) {
    List<Task> tasksToDisplay =
        taskProvider.isDateFiltered
            ? taskProvider.getTasksByDate(_selectedDay!)
            : taskProvider.allTasks;

    if (tasksToDisplay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              taskProvider.isDateFiltered
                  ? 'No tasks for this date'
                  : 'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              taskProvider.isDateFiltered
                  ? 'Try selecting a different date'
                  : 'Tap + to create your first task',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (taskProvider.isDateFiltered) {
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
                      taskProvider.setDateFilter(date);
                      setState(() {
                        _selectedDay = date;
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

  Widget _buildTodayTab(TaskProvider taskProvider) {
    List<Task> todayTasks = taskProvider.getTodayTasks();

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

  Widget _buildUpcomingTab(TaskProvider taskProvider) {
    List<Task> upcomingTasks = taskProvider.getUpcomingTasks();

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

  Widget _buildCompletedTab(TaskProvider taskProvider) {
    List<Task> completedTasks = taskProvider.getCompletedTasks();

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
