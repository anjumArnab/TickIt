import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/hive/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification ID
  static const int _dailySummaryNotificationId = 999999;

  // Channel ID
  static const String _taskReminderChannelId = 'task_reminders';
  static const String _dailySummaryChannelId = 'daily_summary';

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Task notification tapped: ${response.payload}');
    // TODO: Add navigation logic here (navigate to the specific task or homepage)
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Request permissions for iOS
      final bool? iosGranted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Request permissions for Android 13+
      final bool? androidGranted =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();

      debugPrint(
        'Task notification permissions - iOS: $iosGranted, Android: $androidGranted',
      );

      return iosGranted ?? androidGranted ?? true;
    } catch (e) {
      debugPrint('Error requesting task notification permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      // Check Android
      final bool? androidEnabled =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled();

      if (androidEnabled != null) {
        return androidEnabled;
      }

      // For iOS, we assume enabled if permissions were granted
      return true;
    } catch (e) {
      debugPrint('Error checking task notification status: $e');
      return false;
    }
  }

  /// Parse task time string
  TimeOfDay? _parseTaskTime(String timeString) {
    try {
      // Remove extra spaces
      final cleanTime = timeString.trim();

      // Extract time parts
      final timePattern = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = timePattern.firstMatch(cleanTime);

      if (match == null) {
        debugPrint('Invalid time format: $timeString');
        return null;
      }

      int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);
      final String period = match.group(3)!.toUpperCase();

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing task time "$timeString": $e');
      return null;
    }
  }

  /// Combine date and time to create a DateTime
  DateTime? _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Schedule a notification for a specific task
  Future<void> scheduleTaskNotification(Task task, int taskKey) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return;
    }

    // Parse the task time
    final timeOfDay = _parseTaskTime(task.time);
    if (timeOfDay == null) {
      debugPrint('Could not parse task time: ${task.time}');
      return;
    }

    // Combine task date and time
    final scheduledDateTime = _combineDateTime(task.date, timeOfDay);
    if (scheduledDateTime == null) {
      debugPrint('Could not create scheduled DateTime for task');
      return;
    }

    // Check if the scheduled time is in the future
    if (scheduledDateTime.isBefore(DateTime.now())) {
      debugPrint('Task scheduled time is in the past. Skipping notification.');
      return;
    }

    try {
      // Convert DateTime to TZDateTime
      final scheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

      // Create notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _taskReminderChannelId,
            'Task Reminders',
            channelDescription: 'Notifications for scheduled task reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Notification title and body
      final title = 'Task Reminder';
      final body = 'You have to work with ${task.title}';

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        taskKey, // Using task key as notification ID
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: taskKey.toString(),
      );

      debugPrint(
        'Scheduled notification for task "${task.title}" at $scheduledDateTime (ID: $taskKey)',
      );
    } catch (e) {
      debugPrint('Error scheduling notification for task $taskKey: $e');
    }
  }

  /// Schedule daily morning notification at 7:00 AM
  Future<void> scheduleDailySummaryNotification(int taskCount) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return;
    }

    try {
      // Cancel existing daily notification
      await _notificationsPlugin.cancel(_dailySummaryNotificationId);

      // Get today's date at 7:00 AM
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 7, 0);

      // If it is already past 7 AM today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Convert to TZDateTime
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Create notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _dailySummaryChannelId,
            'Daily Summary',
            channelDescription: 'Daily summary of tasks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Notification title and body
      final title = 'Good Morning!';
      final body =
          taskCount > 0
              ? 'You have $taskCount ${taskCount == 1 ? 'task' : 'tasks'} for today'
              : 'You have no tasks for today';

      // Schedule daily repeating notification
      await _notificationsPlugin.zonedSchedule(
        _dailySummaryNotificationId,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        'Scheduled daily summary notification at 7:00 AM (next: $scheduledDate)',
      );
    } catch (e) {
      debugPrint('Error scheduling daily summary notification: $e');
    }
  }

  /// Update daily summary notification based on today's tasks
  Future<void> updateDailySummaryNotification(List<Task> todayTasks) async {
    await scheduleDailySummaryNotification(todayTasks.length);
  }

  /// Cancel a notification for a specific task
  Future<void> cancelTaskNotification(int taskKey) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return;
    }

    try {
      await _notificationsPlugin.cancel(taskKey);
      debugPrint('Cancelled notification for task key: $taskKey');
    } catch (e) {
      debugPrint('Error cancelling notification for task $taskKey: $e');
    }
  }

  /// Cancel all task notifications except daily summary
  Future<void> cancelAllTaskNotifications() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return;
    }

    try {
      final pendingNotifications = await getPendingNotifications();

      for (final notification in pendingNotifications) {
        // Skip daily summary notification
        if (notification.id != _dailySummaryNotificationId) {
          await _notificationsPlugin.cancel(notification.id);
        }
      }

      debugPrint('Cancelled all task notifications');
    } catch (e) {
      debugPrint('Error cancelling all task notifications: $e');
    }
  }

  /// Cancel all notifications including daily summary
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return;
    }

    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return [];
    }

    try {
      final pendingNotifications =
          await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('Pending task notifications: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Reschedule notification
  Future<void> rescheduleTaskNotification(Task task, int taskKey) async {
    // Cancel existing notification
    await cancelTaskNotification(taskKey);

    // Schedule new notification
    await scheduleTaskNotification(task, taskKey);
  }

  /// Schedule notifications for multiple tasks
  Future<void> scheduleMultipleTaskNotifications(
    Map<int, Task> tasksWithKeys,
  ) async {
    int scheduled = 0;
    for (final entry in tasksWithKeys.entries) {
      final taskKey = entry.key;
      final task = entry.value;

      await scheduleTaskNotification(task, taskKey);
      scheduled++;
    }
    debugPrint('Scheduled $scheduled task notifications');
  }

  /// Check if a specific notification is pending
  Future<bool> isNotificationPending(int taskKey) async {
    final pendingNotifications = await getPendingNotifications();
    return pendingNotifications.any(
      (notification) => notification.id == taskKey,
    );
  }

  /// Show an immediate notification for testing purpose
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call init() first.');
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _taskReminderChannelId,
            'Task Reminders',
            channelDescription: 'Notifications for scheduled task reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(id, title, body, notificationDetails);

      debugPrint('Showed immediate notification: $title');
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  /// Get notification details for debugging
  Future<Map<String, dynamic>> getNotificationDebugInfo() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      final isEnabled = await areNotificationsEnabled();

      return {
        'isInitialized': _isInitialized,
        'notificationsEnabled': isEnabled,
        'pendingCount': pendingNotifications.length,
        'pendingNotifications':
            pendingNotifications
                .map(
                  (n) => {
                    'id': n.id,
                    'title': n.title,
                    'body': n.body,
                    'payload': n.payload,
                  },
                )
                .toList(),
      };
    } catch (e) {
      return {'error': e.toString(), 'isInitialized': _isInitialized};
    }
  }

  /// Refresh all task notifications after app restarts
  Future<void> refreshAllTaskNotifications(
    Map<int, Task> allTasksWithKeys,
  ) async {
    // Cancel all existing task notifications
    await cancelAllTaskNotifications();

    // Reschedule all future tasks
    await scheduleMultipleTaskNotifications(allTasksWithKeys);

    debugPrint('Refreshed all task notifications');
  }
}
