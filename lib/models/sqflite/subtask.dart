class Subtask {
  int? id;
  int? taskId;
  String title;
  bool isCompleted;

  Subtask({
    this.id,
    this.taskId,
    required this.title,
    this.isCompleted = false,
  });

  // Convert Subtask to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // Create Subtask from Map
  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as int?,
      taskId: map['taskId'] as int?,
      title: map['title'] as String,
      isCompleted: map['isCompleted'] == 1,
    );
  }
}