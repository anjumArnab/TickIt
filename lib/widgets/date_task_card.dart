import 'package:flutter/material.dart';

class DateTaskCard extends StatelessWidget {
  final DateTime date;
  final int taskCount;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? dateBackgroundColor;
  final Color? dateTextColor;
  final Color? weekdayTextColor;
  final Color? taskCountBackgroundColor;
  final Color? taskCountTextColor;
  final double? borderRadius;
  final double? borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const DateTaskCard({
    super.key,
    required this.date,
    required this.taskCount,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.dateBackgroundColor,
    this.dateTextColor,
    this.weekdayTextColor,
    this.taskCountBackgroundColor,
    this.taskCountTextColor,
    this.borderRadius,
    this.borderWidth,
    this.padding,
    this.margin,
  });

  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(Duration(days: 1));
    DateTime dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return weekdays[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          child: Container(
            padding:
                padding ??
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
              border: Border.all(
                color: borderColor ?? Colors.grey.withOpacity(0.3),
                width: borderWidth ?? 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: dateBackgroundColor ?? Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: dateTextColor ?? Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getWeekdayName(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: weekdayTextColor ?? Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: taskCountBackgroundColor ?? Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$taskCount tasks',
                    style: TextStyle(
                      fontSize: 10,
                      color: taskCountTextColor ?? Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
