class ScheduleItem {
  final int week;
  final int day;
  final int lesson;
  final String discipline;
  final String lecturer;
  final String auditorium;
  final String type;
  final List<String> dates;

  ScheduleItem({
    required this.week,
    required this.day,
    required this.lesson,
    required this.discipline,
    required this.lecturer,
    required this.auditorium,
    required this.type,
    required this.dates,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      week: json['week'],
      day: json['day'],
      lesson: json['class'],
      discipline: json['discipline'],
      lecturer: json['lecturer'],
      auditorium: json['auditorium'],
      type: json['type'],
      dates: List<String>.from(json['dates']),
    );
  }
}
