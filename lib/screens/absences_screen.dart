import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../services/shedule_service.dart';
import '../models/shedule_item.dart';
import '../services/attendance_service.dart';
import 'student_absence_detail_screen.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  final studentService = StudentService();
  final attendanceService = AttendanceService();

  List students = [];
  List records = [];
  List<ScheduleItem> schedule = [];

  DateTime selectedDate = DateTime.now();
  ScheduleItem? selectedLesson;
  DateTime? scheduleStartDate;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    students = await studentService.getStudents();
    records = await attendanceService.loadAttendance();
    final response = await ScheduleService.fetch();
    schedule = response.classes;
    scheduleStartDate = response.startDate;

    if (mounted) {
      setState(() {});
    }
  }

  int getCurrentWeek(DateTime targetDate, DateTime startDate) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = target.difference(start).inDays ~/ 7;
    final week = diff % 2 == 0 ? 1 : 2;
    return week == 1 ? 2 : 1;
  }

  List<ScheduleItem> getLessonsForDate(DateTime date, DateTime semesterStart) {
    // Раньше было: final currentWeek = getCurrentWeek(semesterStart);
    // Теперь:
    final currentWeek = getCurrentWeek(date, semesterStart);
    final weekday = date.weekday; // 1-Пн, 7-Вс

    return schedule
        .where((e) => e.day == weekday && e.week == currentWeek)
        .toList()
      ..sort((a, b) => a.lesson.compareTo(b.lesson));
  }

  List filteredRecords() {
    return records.where((r) {
      final date = DateTime.parse(r['date']);
      return date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day &&
          (selectedLesson == null || r['lesson'] == selectedLesson!.lesson);
    }).toList();
  }

  int calculateHours(String studentId) {
    final studentRecords = records.where(
      (r) => r['studentId'] == studentId && r['status'] == 'absent',
    );
    return studentRecords.length * 2;
  }

  @override
  Widget build(BuildContext context) {
    final lessons = scheduleStartDate == null
        ? <ScheduleItem>[]
        : getLessonsForDate(selectedDate, scheduleStartDate!);

    if (selectedLesson != null &&
        !lessons.any((l) => l.lesson == selectedLesson!.lesson)) {
      selectedLesson = null;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                      selectedLesson = null;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<ScheduleItem>(
                  isExpanded: true,
                  hint: const Text("Пара"),
                  value: selectedLesson,
                  items: lessons
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            "${s.lesson}. ${s.discipline}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (s) => setState(() => selectedLesson = s),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (_, i) {
              final student = students[i];
              final studentRecords = filteredRecords().where(
                (r) => r['studentId'] == student['id'],
              );
              final record = studentRecords.isNotEmpty
                  ? studentRecords.first
                  : null;

              AttendanceStatus? status;
              String? markedBy;
              if (record != null) {
                markedBy = record['markedBy'] as String?;
                switch (record['status']) {
                  case 'present':
                    status = AttendanceStatus.present;
                    break;
                  case 'absent':
                    status = AttendanceStatus.absent;
                    break;
                  case 'excused':
                    status = AttendanceStatus.excused;
                    break;
                }
              } else {
                status = AttendanceStatus.present;
              }

              Widget statusWidget;
              switch (status) {
                case AttendanceStatus.present:
                  statusWidget = const Text(
                    "✅ Присутствует",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                  break;
                case AttendanceStatus.absent:
                  statusWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "❌ Пропуск",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (markedBy != null)
                        Text(
                          "Отметил: $markedBy",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  );
                  break;
                case AttendanceStatus.excused:
                  statusWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "📄 Уважительная",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (markedBy != null)
                        Text(
                          "Отметил: $markedBy",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  );
                  break;
                default:
                  statusWidget = const SizedBox();
              }

              return Card(
                child: ListTile(
                  title: Text(student['name']),
                  subtitle: Text(
                    "Пропущено часов: ${calculateHours(student['id'])}",
                  ),
                  trailing: statusWidget,
                  onTap: () {
                    // Проверяем, что данные для перехода загружены
                    if (scheduleStartDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Данные расписания еще загружаются..."),
                        ),
                      );
                      return;
                    }

                    // Переход на экран с деталями
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentAbsenceDetailScreen(
                          student: student,
                          allRecords: records.cast<Map<String, dynamic>>(), // Передаем ВСЕ записи
                          allScheduleItems: schedule, // Передаем ВСЕ расписание
                          semesterStartDate:
                              scheduleStartDate!, // Передаем дату начала семестра
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
