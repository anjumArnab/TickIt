// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/workspace_card.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key});

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search workspaces...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Workspaces List
            Expanded(
              child: ListView(
                children: [
                  WorkspaceCard(
                    title: 'Personal',
                    taskCount: 12,
                    completedCount: 3,
                    lastUpdated: '2 hours ago',
                    color: const Color(0xFFFF6B6B),
                    icon: 'P',
                  ),
                  const SizedBox(height: 16),
                  WorkspaceCard(
                    title: 'Work',
                    taskCount: 28,
                    completedCount: 15,
                    lastUpdated: '1 hour ago',
                    color: const Color(0xFF4A90E2),
                    icon: 'W',
                  ),
                  const SizedBox(height: 16),
                  WorkspaceCard(
                    title: 'Freelance',
                    taskCount: 8,
                    completedCount: 2,
                    lastUpdated: '3 hours ago',
                    color: const Color(0xFF4ECDC4),
                    icon: 'F',
                  ),
                  const SizedBox(height: 16),
                  WorkspaceCard(
                    title: 'Projects',
                    taskCount: 15,
                    completedCount: 7,
                    lastUpdated: '5 hours ago',
                    color: const Color(0xFFFFD93D),
                    icon: 'Pr',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
