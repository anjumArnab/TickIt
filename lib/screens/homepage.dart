import 'package:flutter/material.dart';
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

  // Sample tasks data grouped by date
  final List<Task> _allTasks = [
    // Today's tasks
    Task(
      title: 'Design Homepage',
      time: '10:00 AM - 12:00 PM',
      progress: '2/5',
      flagColor: Colors.orange,
      subtasks: ['Create wireframe', 'Add images', 'Review layout'],
      date: DateTime.now(),
    ),
    Task(
      title: 'Team Meeting',
      time: '2:00 PM - 3:00 PM',
      progress: '1/3',
      flagColor: Colors.blue,
      subtasks: ['Prepare agenda', 'Review documents', 'Send invites'],
      date: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'TickIt',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GestureDetector(
        // Close calendar when tapping outside
        onTap: _closeCalendar,
        child: Column(
          children: [
            // Tab Bar
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
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
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
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calendar section that expands from bottom nav
          if (selectedBottomIndex == 0 && _showCalendar)
            ExpandedCalendar(
              onClose: _closeCalendar, // Pass close callback
            ),

          // Bottom Navigation Bar
          _buildBottomNavigationBar(),
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
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),

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

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            Icons.timeline,
            'Timeline',
            0,
            selectedBottomIndex == 0,
          ),
          _buildBottomNavItem(
            Icons.view_module,
            'Board',
            1,
            selectedBottomIndex == 1,
          ),
          _buildBottomNavItem(
            Icons.help_outline,
            'Unplanned',
            2,
            selectedBottomIndex == 2,
          ),
          _buildBottomNavItem(
            Icons.folder_outlined,
            'Workspace',
            3,
            selectedBottomIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    int index,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBottomIndex = index;
          // Show calendar when Timeline is tapped, hide for others
          if (index == 0) {
            _showCalendar = !_showCalendar; // Toggle calendar on Timeline tap
          } else {
            _showCalendar = false; // Hide calendar for other tabs
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue[800] : Colors.grey[600],
              size: 15,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue[800] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
