import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../services/shedule_service.dart';
import '../models/shedule_item.dart';

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
    // Подгружаем посещаемость
    records = await attendanceService.loadAttendance();
    // Подгружаем расписание
    final response = await ScheduleService.fetch();
    schedule = response.classes;
    scheduleStartDate = response.startDate;

    schedule = response.classes;
    setState(() {});
  }

  int getCurrentWeek(DateTime startDate) {
    final today = DateTime.now();
    final diff =
        DateTime(today.year, today.month, today.day)
            .difference(
              DateTime(startDate.year, startDate.month, startDate.day),
            )
            .inDays ~/
        7;
    final week = diff % 2 == 0 ? 1 : 2;
    return week == 1 ? 2 : 1; // фикс, как на твоем ScheduleScreen
  }

  List<ScheduleItem> getLessonsForDate(DateTime date, DateTime semesterStart) {
    final currentWeek = getCurrentWeek(semesterStart);
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
    // Получаем список пар для выбранной даты
    final lessons = scheduleStartDate == null
        ? <ScheduleItem>[]
        : getLessonsForDate(selectedDate, scheduleStartDate!);

    // Сбрасываем выбранную пару, если её нет в новом дне
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
              // 🔹 Выбор даты
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

              // 🔹 Выбор пары
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

        // 🔹 Список студентов (Только просмотр)
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

              // Определяем статус
              AttendanceStatus? status;
              if (record != null) {
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

              // Создаем красивый текст вместо выпадающего списка
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
                  statusWidget = const Text(
                    "❌ Пропуск",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                  break;
                case AttendanceStatus.excused:
                  statusWidget = const Text(
                    "📄 Уважительная",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                  // ИСПРАВЛЕНИЕ: Теперь здесь просто текстовый виджет, а не DropdownButton
                  trailing: statusWidget,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
