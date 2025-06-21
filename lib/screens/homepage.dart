// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import '../screens/drawer.dart';
import '../screens/taskpage.dart';
import '../screens/pomodoro.dart';
import '../screens/workspace.dart';
import '../model/task.dart';
import '../widgets/calendar.dart';
import '../widgets/date_task_card.dart';
import '../widgets/task_group.dart';
import '../services/db_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  int selectedBottomIndex = 0;
  late TabController _tabController;
  DateTime? _selectedDay;
  bool _showCalendar = false;

  // Database service instance
  final DBService _dbService = DBService.instance;

  // Tasks loaded from database
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

  // Load tasks from database
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

  // Refresh tasks after operations
  void _refreshTasks() {
    _loadTasks();
  }

  // Function to close calendar
  void _closeCalendar() {
    if (_showCalendar) {
      setState(() {
        _showCalendar = false;
      });
    }
  }

  // Group tasks by date
  Map<DateTime, List<Task>> _groupTasksByDate() {
    Map<DateTime, List<Task>> groupedTasks = {};

    for (Task task in _allTasks) {
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

    return groupedTasks;
  }

  // Navigate to task page for editing with proper task key
  void _navToTaskPageForEdit(BuildContext context, Task task) async {
    // Find the task key from the database
    int? taskKey;

    // Get all tasks from the box with their keys
    final box = _dbService.tasksBox;
    for (var key in box.keys) {
      final boxTask = box.get(key);
      if (boxTask != null &&
          boxTask.title == task.title &&
          boxTask.date == task.date &&
          boxTask.time == task.time) {
        taskKey = key as int;
        break;
      }
    }

    if (taskKey != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => TaskPage(
                task: task,
                taskKey: taskKey, // Pass the task key
              ),
        ),
      );

      if (result != null) {
        _refreshTasks();
      }
    } else {
      // Show error if task key not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Task not found for editing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convert color value to Color object
  Color _getColorFromValue(int colorValue) {
    return Color(colorValue);
  }

  // Get the current screen based on selected bottom nav index
  Widget _getCurrentScreen() {
    switch (selectedBottomIndex) {
      case 0:
        return _buildTimelineScreen();
      case 1:
        return PomodoroTimer();
      case 2:
        return Workspace();
      default:
        return _buildTimelineScreen();
    }
  }

  // Get app bar title based on selected tab
  String _getAppBarTitle() {
    switch (selectedBottomIndex) {
      case 0:
        return 'Tick It';
      case 1:
        return 'Pomodoro Timer';
      case 2:
        return 'Workspace';
      default:
        return 'Tick It';
    }
  }

  // Build the timeline screen (original homepage content)
  Widget _buildTimelineScreen() {
    return GestureDetector(
      // Close calendar when tapping outside
      onTap: _closeCalendar,
      child: Column(
        children: [
          // Tab Bar - only show for timeline
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                // Close calendar when switching tabs
                _closeCalendar();
              },
              tabs: [
                Tab(text: 'All todos'),
                Tab(text: 'Today'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
              labelColor: Colors.blue[800],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[800],
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),

          // Tab Bar View
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
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
        ],
      ),
    );
  }

  void _navToTaskPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskPage()),
    );

    // Refresh tasks if a new task was added
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
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Add refresh button
          if (selectedBottomIndex == 0)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshTasks,
            ),
        ],
      ),
      drawer: AppDrawer(),
      body: _getCurrentScreen(),
      // Only show floating action button on Timeline tab
      floatingActionButton:
          selectedBottomIndex == 0
              ? FloatingActionButton(
                backgroundColor: Colors.green,
                shape: const CircleBorder(),
                onPressed: () => _navToTaskPage(context),
                child: Icon(Icons.add, color: Colors.white),
              )
              : null,

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calendar section that expands from bottom nav - only for timeline
          if (selectedBottomIndex == 0 && _showCalendar) ExpandedCalendar(),

          // Bottom Navigation Bar with removed container background
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                selectedItemColor: Colors.green[800],
                unselectedItemColor: Colors.grey[600],
                backgroundColor: Colors.white,
                type: BottomNavigationBarType.fixed,
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: selectedBottomIndex,
              onTap: (index) {
                setState(() {
                  // Handle calendar logic only for timeline tab
                  if (index == 0) {
                    if (selectedBottomIndex == 0) {
                      // If already on timeline, toggle calendar
                      _showCalendar = !_showCalendar;
                    } else {
                      // Switching to timeline, don't show calendar initially
                      _showCalendar = false;
                    }
                  } else {
                    // Hide calendar for other tabs
                    _showCalendar = false;
                  }

                  // Update selected index
                  selectedBottomIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.green[800],
              unselectedItemColor: Colors.grey[600],
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 5,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              enableFeedback: false, // Removes ripple effect
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.timeline),
                  label: 'Timeline',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer),
                  label: 'Pomodoro',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_outlined),
                  label: 'Workspace',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTodosTab() {
    if (_allTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to create your first task',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    Map<DateTime, List<Task>> groupedTasks = _groupTasksByDate();
    List<DateTime> sortedDates =
        groupedTasks.keys.toList()..sort((a, b) => a.compareTo(b));

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 15),

          // Loop through each date and display tasks
          ...sortedDates.map((date) {
            List<Task> tasksForDate = groupedTasks[date]!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header using DateTaskCard
                  DateTaskCard(
                    date: date,
                    taskCount: tasksForDate.length,
                    onTap: () {
                      // Handle date card tap - could navigate to day view
                      print('Tapped date: ${date.toString()}');
                    },
                  ),

                  SizedBox(height: 12),

                  // Tasks for this date
                  ...tasksForDate.map((task) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
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
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    // Use database service method for today's tasks
    List<Task> todayTasks = _dbService.getTodayTasks();

    if (todayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.today, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
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
          SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children:
                  todayTasks.map((task) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
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
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }).toList(),
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    // Use database service method for upcoming tasks
    List<Task> upcomingTasks = _dbService.getUpcomingTasks();

    if (upcomingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
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
          SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children:
                  upcomingTasks.map((task) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
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
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }).toList(),
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    // Use database service method for completed tasks
    List<Task> completedTasks = _dbService.getCompletedTasks();

    if (completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
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
          SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children:
                  completedTasks.map((task) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
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
                        onTap: () => _navToTaskPageForEdit(context, task),
                      ),
                    );
                  }).toList(),
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }
}
