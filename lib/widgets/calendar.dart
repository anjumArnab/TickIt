import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ExpandedCalendar extends StatefulWidget {
  final VoidCallback? onClose;

  const ExpandedCalendar({super.key, this.onClose});

  @override
  State<ExpandedCalendar> createState() => _ExpandedCalendarState();
}

class _ExpandedCalendarState extends State<ExpandedCalendar> {
  bool _showFullCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Get next 7 days starting from today
  List<DateTime> _getNext7Days() {
    DateTime today = DateTime.now();
    return List.generate(7, (index) => today.add(Duration(days: index)));
  }

  // Get weekday abbreviation
  String _getWeekdayAbbr(DateTime date) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return weekdays[date.weekday % 7];
  }

  // Get month name
  String _getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> next7Days = _getNext7Days();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important: Let the column size itself
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(_focusedDay)} ${_focusedDay.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFullCalendar = !_showFullCalendar;
                      });
                    },
                    child: Icon(
                      _showFullCalendar
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 6),
                  // Close button
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 7-day horizontal view (always visible)
          if (!_showFullCalendar) ...[
            const SizedBox(height: 8),
            SizedBox(
              // Changed from Container to SizedBox
              height: 55,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    next7Days.map((day) {
                      bool isSelected =
                          _selectedDay != null && isSameDay(_selectedDay!, day);
                      bool isToday = isSameDay(day, DateTime.now());

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                              _focusedDay = day;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.blue
                                      : isToday
                                      ? Colors.blue[100]
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isToday && !isSelected
                                        ? Colors.blue
                                        : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getWeekdayAbbr(day),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : isToday
                                            ? Colors.blue
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],

          // Full Calendar (shown when expanded)
          if (_showFullCalendar) ...[
            const SizedBox(height: 12),
            // Removed fixed height container - let TableCalendar size itself
            TableCalendar<dynamic>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month, // Explicitly set format
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronVisible: true,
                rightChevronVisible: true,
                titleTextStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                headerPadding: EdgeInsets.symmetric(vertical: 4),
                leftChevronPadding: EdgeInsets.all(8),
                rightChevronPadding: EdgeInsets.all(8),
              ),
              calendarStyle: CalendarStyle(
                cellMargin: EdgeInsets.all(1),
                defaultTextStyle: TextStyle(fontSize: 11),
                weekendTextStyle: TextStyle(
                  color: Colors.red[400],
                  fontSize: 11,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue[200],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                tablePadding: EdgeInsets.symmetric(horizontal: 8),
                cellPadding: EdgeInsets.all(2),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                weekendStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[400],
                ),
              ),
            ),
            const SizedBox(height: 8), // Add some bottom padding
          ],
        ],
      ),
    );
  }
}
