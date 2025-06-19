// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class TaskGroup extends StatefulWidget {
  final String title;
  final String time;
  final String progress;
  final Color flagColor;
  final List<String> subtasks;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final String? workspace; // New workspace parameter
  final Color? workspaceColor; // Optional workspace color

  const TaskGroup({
    super.key,
    required this.title,
    required this.time,
    required this.progress,
    required this.flagColor,
    required this.subtasks,
    this.isSelected = false,
    this.onSelectionChanged,
    this.workspace,
    this.workspaceColor,
  });

  @override
  State<TaskGroup> createState() => _TaskGroupState();
}

class _TaskGroupState extends State<TaskGroup> {
  late bool _isSelected;
  final GlobalKey _contentKey = GlobalKey();
  int? _selectedSubtaskIndex; // Track which subtask is selected

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  double _calculateContentHeight() {
    // Base height calculation
    double baseHeight =
        50; // Approximate height for title, time, and progress rows

    // Add workspace height if present
    if (widget.workspace != null) {
      baseHeight += 25; // Additional height for workspace container
    }

    double subtaskHeight =
        widget.subtasks.length * 35; // Each subtask is approximately 35px tall
    return baseHeight + subtaskHeight;
  }

  // Get workspace color or default
  Color _getWorkspaceColor() {
    if (widget.workspaceColor != null) {
      return widget.workspaceColor!;
    }

    // Default colors based on workspace name
    switch (widget.workspace?.toLowerCase()) {
      case 'personal':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'freelance':
        return Colors.purple;
      case 'study':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline radio button and line
        Column(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _isSelected,
              onChanged: (value) {
                setState(() {
                  _isSelected = value ?? false;
                });
                widget.onSelectionChanged?.call(_isSelected);
              },
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Container(
              width: 2,
              height: _calculateContentHeight(),
              color: Colors.grey,
            ),
          ],
        ),
        SizedBox(width: 16),
        // Task content
        Expanded(
          key: _contentKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: widget.flagColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 5),
                  Text(
                    widget.time,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    widget.progress,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  // Workspace container - positioned in the red highlighted area
                  if (widget.workspace != null) ...[
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getWorkspaceColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getWorkspaceColor().withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 12,
                            color: _getWorkspaceColor(),
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.workspace!,
                            style: TextStyle(
                              color: _getWorkspaceColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 6),
              ...widget.subtasks.asMap().entries.map((entry) {
                int index = entry.key;
                String subtask = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.7,
                        child: Radio<int>(
                          value: index,
                          groupValue: _selectedSubtaskIndex,
                          onChanged: (value) {
                            setState(() {
                              _selectedSubtaskIndex = value;
                            });
                          },
                          activeColor: Colors.blue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Expanded(
                        child: Text(subtask, style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
