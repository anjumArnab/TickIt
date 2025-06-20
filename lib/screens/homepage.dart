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

  // Sample tasks data grouped by date with workspace information
  final List<Task> _allTasks = [
    // Today's tasks
    Task(
      title: 'Design Homepage',
      time: '10:00 AM - 12:00 PM',
      progress: '2/5',
      flagColor: Colors.orange,
      subtasks: ['Create wireframe', 'Add images', 'Review layout'],
      date: DateTime.now(),
      workspace: 'Work',
      workspaceColor: Colors.blue,
    ),
    Task(
      title: 'Team Meeting',
      time: '2:00 PM - 3:00 PM',
      progress: '1/3',
      flagColor: Colors.blue,
      subtasks: ['Prepare agenda', 'Review documents', 'Send invites'],
      date: DateTime.now(),
      workspace: 'Work',
      workspaceColor: Colors.blue,
    ),

    // Tomorrow's tasks
    Task(
      title: 'Code Review',
      time: '9:00 AM - 11:00 AM',
      progress: '0/4',
      flagColor: Colors.red,
      subtasks: [
        'Review PR #123',
        'Test functionality',
        'Update documentation',
        'Merge changes',
      ],
      date: DateTime.now().add(Duration(days: 1)),
      workspace: 'Freelance',
      workspaceColor: Colors.purple,
    ),
    Task(
      title: 'Client Presentation',
      time: '3:00 PM - 4:30 PM',
      progress: '3/6',
      flagColor: Colors.green,
      subtasks: [
        'Prepare slides',
        'Practice presentation',
        'Setup demo',
        'Prepare Q&A',
        'Send materials',
        'Schedule follow-up',
      ],
      date: DateTime.now().add(Duration(days: 1)),
      workspace: 'Freelance',
      workspaceColor: Colors.purple,
    ),

    // Day after tomorrow
    Task(
      title: 'Database Optimization',
      time: '10:00 AM - 1:00 PM',
      progress: '1/4',
      flagColor: Colors.purple,
      subtasks: [
        'Analyze queries',
        'Create indexes',
        'Test performance',
        'Document changes',
      ],
      date: DateTime.now().add(Duration(days: 2)),
      workspace: 'Personal',
      workspaceColor: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        return 'TickIt';
      case 1:
        return 'Pomodoro Timer';
      case 2:
        return 'Workspace';
      default:
        return 'TickIt';
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
            child: TabBarView(
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

  void _navToTaskPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskPage()),
    );
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
                        flagColor: task.flagColor,
                        subtasks: task.subtasks,
                        workspace: task.workspace, // Pass workspace
                        workspaceColor:
                            task.workspaceColor, // Pass workspace color
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
    // Filter tasks for today only
    DateTime today = DateTime.now();
    DateTime todayOnly = DateTime(today.year, today.month, today.day);

    List<Task> todayTasks =
        _allTasks.where((task) {
          DateTime taskDate = DateTime(
            task.date.year,
            task.date.month,
            task.date.day,
          );
          return taskDate == todayOnly;
        }).toList();

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
                        flagColor: task.flagColor,
                        subtasks: task.subtasks,
                        workspace: task.workspace,
                        workspaceColor: task.workspaceColor,
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
    // Filter tasks for upcoming days (not today)
    DateTime today = DateTime.now();
    DateTime todayOnly = DateTime(today.year, today.month, today.day);

    List<Task> upcomingTasks =
        _allTasks.where((task) {
          DateTime taskDate = DateTime(
            task.date.year,
            task.date.month,
            task.date.day,
          );
          return taskDate.isAfter(todayOnly);
        }).toList();

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
                        flagColor: task.flagColor,
                        subtasks: task.subtasks,
                        workspace: task.workspace,
                        workspaceColor: task.workspaceColor,
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
}
