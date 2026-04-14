import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../services/shedule_service.dart';
import '../models/shedule_item.dart';
import '../services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final studentService = StudentService();
  final attendanceService = AttendanceService();

  DateTime selectedDate = DateTime.now();
  ScheduleItem? selectedLesson;
  ScheduleResponse? scheduleData;

  List students = [];
  List records = [];
  Map<String, AttendanceStatus> statuses = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    students = await studentService.getStudents();
    records = await attendanceService.loadAttendance();
    scheduleData = await ScheduleService.fetch();
    _updateStatuses();
    if (mounted) setState(() {});
  }

  int getCurrentWeek(DateTime targetDate, DateTime startDate) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = target.difference(start).inDays ~/ 7;
    final week = diff % 2 == 0 ? 1 : 2;
    return week == 1 ? 2 : 1;
  }

  List<ScheduleItem> getLessonsForDate() {
    if (scheduleData == null) return [];
    final currentWeek = getCurrentWeek(selectedDate, scheduleData!.startDate);
    final weekday = selectedDate.weekday;
    return scheduleData!.classes
        .where((e) => e.day == weekday && e.week == currentWeek)
        .toList()
      ..sort((a, b) => a.lesson.compareTo(b.lesson));
  }

  void _updateStatuses() {
    statuses.clear();
    if (selectedLesson == null) return;
    for (var student in students) {
      final existingRecord = records.where((r) {
        final d = DateTime.parse(r['date']);
        return d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day &&
            r['lesson'] == selectedLesson!.lesson &&
            r['studentId'] == student['id'];
      }).toList();
      if (existingRecord.isNotEmpty) {
        final statusStr = existingRecord.first['status'];
        if (statusStr == 'present') {
          statuses[student['id']] = AttendanceStatus.present;
        } else if (statusStr == 'absent') {
          statuses[student['id']] = AttendanceStatus.absent;
        } else if (statusStr == 'excused') {
          statuses[student['id']] = AttendanceStatus.excused;
        }
      } else {
        statuses[student['id']] = AttendanceStatus.present;
      }
    }
  }

  void save() async {
    if (selectedLesson == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Сначала выберите пару!")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final signature = prefs.getString('user_signature');

    if (signature == null || signature.trim().isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Необходима подпись"),
          content: const Text(
            "Чтобы сохранить изменения, необходимо указать вашу подпись.\n\nПерейдите в Настройки -> Подпись для отметок.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Понятно"),
            ),
          ],
        ),
      );
      return; // Прерываем сохранение
    }

    // Показываем индикатор загрузки для наглядности
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Сохранение..."),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Вызываем новый оптимизированный метод, передавая все данные разом
      await attendanceService.updateAttendanceBatch(
        statuses: statuses,
        date: selectedDate,
        lesson: selectedLesson!.lesson,
        markedBy: signature,
      );

      // Обновляем локальные данные после успешного сохранения
      records = await attendanceService.loadAttendance();

      if (mounted) {
        // Убираем старый SnackBar и показываем новый
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Отметки сохранены ✅")));
      }
    } catch (e) {
      // Обработка ошибок
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
      }
    }

    for (var student in students) {
      final status = statuses[student['id']] ?? AttendanceStatus.present;
      await attendanceService.markAttendance(
        studentId: student['id'],
        date: selectedDate,
        lesson: selectedLesson!.lesson,
        status: status,
        markedBy: signature,
      );
    }

    records = await attendanceService.loadAttendance();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Отметки сохранены ✅")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (scheduleData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayLessons = getLessonsForDate();

    if (selectedLesson != null &&
        !todayLessons.any((l) => l.lesson == selectedLesson!.lesson)) {
      selectedLesson = null;
      _updateStatuses();
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
                      _updateStatuses();
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<ScheduleItem>(
                  isExpanded: true,
                  value: selectedLesson,
                  hint: const Text("Выбери пару"),
                  items: todayLessons.map((lesson) {
                    return DropdownMenuItem(
                      value: lesson,
                      child: Text(
                        "${lesson.lesson}. ${lesson.discipline}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (lesson) {
                    setState(() {
                      selectedLesson = lesson;
                      _updateStatuses();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedLesson == null
              ? const Center(
                  child: Text(
                    "Выберите пару для выставления отметок",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final student = students[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(student['name']),
                        trailing: DropdownButton<AttendanceStatus>(
                          value:
                              statuses[student['id']] ??
                              AttendanceStatus.present,
                          items: AttendanceStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s == AttendanceStatus.present
                                    ? "✅ Есть"
                                    : s == AttendanceStatus.absent
                                    ? "❌ Нет"
                                    : "📄 Уваж",
                              ),
                            );
                          }).toList(),
                          onChanged: (s) {
                            setState(() {
                              statuses[student['id']] = s!;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: selectedLesson == null ? null : save,
              icon: const Icon(Icons.save),
              label: const Text("Сохранить изменения"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFD0BCFF),
                foregroundColor: const Color(0xFF381E72),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ... (StudentsScreen остается без изменений)

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final service = StudentService();
  List students = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    students = await service.getStudents();
    setState(() {});
  }

  void _addStudent() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Добавить студента"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              await service.addStudent(controller.text);
              Navigator.pop(context);
              load();
            },
            child: const Text("Добавить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Студенты")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudent,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (_, i) {
          return Card(child: ListTile(title: Text(students[i]['name'])));
        },
      ),
    );
  }
}
