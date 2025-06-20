import 'package:flutter/material.dart';
import 'package:tick_it/screens/account.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // User Account Header
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              );
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
                ),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person_add,
                    size: 32,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              accountName: Text(
                'Guest User',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              accountEmail: Text(
                'Tap to create account',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              arrowColor: Colors.white.withOpacity(0.7),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to home
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.task_outlined,
                  title: 'All Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to all tasks
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.today_outlined,
                  title: 'Today',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to today's tasks
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.upcoming_outlined,
                  title: 'Upcoming',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to upcoming tasks
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.check_circle_outline,
                  title: 'Completed',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to completed tasks
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                _buildDrawerItem(
                  icon: Icons.timer_outlined,
                  title: 'Pomodoro Timer',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to pomodoro timer
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.timeline_outlined,
                  title: 'Timeline',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to timeline
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.folder_outlined,
                  title: 'Workspaces',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to workspaces
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to help
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to about
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.apps, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  'TickIt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  'v1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF007AFF).withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF007AFF) : Colors.grey[600],
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF007AFF) : Colors.grey[800],
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
