import 'package:flutter/material.dart';

class TaskGroup extends StatefulWidget {
  final String title;
  final String time;
  final String progress;
  final Color flagColor;
  final List<String> subtasks;
  final String? workspace;
  final Color? workspaceColor;
  final VoidCallback? onTap;
  final bool isMainTaskCompleted;
  final List<bool> subtaskCompletionStates;
  final VoidCallback? onMainTaskToggle;
  final Function(int)? onSubtaskToggle;

  const TaskGroup({
    super.key,
    required this.title,
    required this.time,
    required this.progress,
    required this.flagColor,
    required this.subtasks,
    this.workspace,
    this.workspaceColor,
    this.onTap,
    this.isMainTaskCompleted = false,
    this.subtaskCompletionStates = const [],
    this.onMainTaskToggle,
    this.onSubtaskToggle,
  });

  @override
  State<TaskGroup> createState() => _TaskGroupState();
}

class _TaskGroupState extends State<TaskGroup> {
  final GlobalKey _contentKey = GlobalKey();

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
    return GestureDetector(
      onTap: widget.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline radio button and line
          Column(
            children: [
              GestureDetector(
                onTap: widget.onMainTaskToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          widget.isMainTaskCompleted
                              ? Colors.green
                              : Colors.grey[400]!,
                      width: 2,
                    ),
                    color:
                        widget.isMainTaskCompleted
                            ? Colors.green
                            : Colors.transparent,
                  ),
                  child:
                      widget.isMainTaskCompleted
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                          : null,
                ),
              ),
              Container(
                width: 2,
                height: _calculateContentHeight(),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(width: 16),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              widget.isMainTaskCompleted
                                  ? Colors.grey[500]
                                  : Colors.black,
                          decoration:
                              widget.isMainTaskCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(
                      widget.time,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.progress,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    // Workspace container
                    if (widget.workspace != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                            const SizedBox(width: 4),
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
                const SizedBox(height: 6),
                ...widget.subtasks.asMap().entries.map((entry) {
                  int index = entry.key;
                  String subtask = entry.value;
                  bool isSubtaskCompleted =
                      index < widget.subtaskCompletionStates.length
                          ? widget.subtaskCompletionStates[index]
                          : false;

                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 0.7,
                          child: GestureDetector(
                            onTap: () => widget.onSubtaskToggle?.call(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSubtaskCompleted
                                          ? Colors.blue
                                          : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color:
                                    isSubtaskCompleted
                                        ? Colors.blue
                                        : Colors.transparent,
                              ),
                              child:
                                  isSubtaskCompleted
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      )
                                      : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            subtask,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isSubtaskCompleted
                                      ? Colors.grey[500]
                                      : Colors.black87,
                              decoration:
                                  isSubtaskCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
