import 'package:flutter/material.dart';
import '../models/shedule_item.dart';

class StudentAbsenceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> allRecords;
  final List<ScheduleItem> allScheduleItems;
  final DateTime semesterStartDate;

  const StudentAbsenceDetailScreen({
    super.key,
    required this.student,
    required this.allRecords,
    required this.allScheduleItems,
    required this.semesterStartDate,
  });

  // Эта функция нужна для поиска детализации пары по дате и номеру
  int _getCurrentWeek(DateTime targetDate, DateTime startDate) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = target.difference(start).inDays ~/ 7;
    final week = diff % 2 == 0 ? 1 : 2;
    return week == 1 ? 2 : 1;
  }

  // Находим информацию о паре по дате и номеру урока
  ScheduleItem? _findLessonDetails(DateTime absenceDate, int lessonNumber) {
    final weekNumber = _getCurrentWeek(absenceDate, semesterStartDate);
    final dayOfWeek = absenceDate.weekday;

    try {
      return allScheduleItems.firstWhere(
        (item) =>
            item.day == dayOfWeek &&
            item.week == weekNumber &&
            item.lesson == lessonNumber,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} (${weekdays[date.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    final studentAbsences = allRecords
        .where(
          (r) => r['studentId'] == student['id'] && r['status'] != 'present',
        )
        .toList();

    studentAbsences.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA); // Сортировка по убыванию
    });

    return Scaffold(
      appBar: AppBar(title: Text("Пропуски: ${student['name']}")),
      body: studentAbsences.isEmpty
          ? const Center(
              child: Text(
                "У этого студента нет пропусков. \nТак держать! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: studentAbsences.length,
              itemBuilder: (context, index) {
                final record = studentAbsences[index];
                final absenceDate = DateTime.parse(record['date']);
                final lessonNumber = record['lesson'] as int;
                final status = record['status'] as String;
                final markedBy = record['markedBy'] as String?;

                final lessonDetails = _findLessonDetails(
                  absenceDate,
                  lessonNumber,
                );

                final isExcused = status == 'excused';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isExcused
                          ? Colors.grey.shade700
                          : Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isExcused
                          ? Colors.grey.shade600
                          : Colors.red.shade900,
                      child: Text(
                        lessonNumber.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      lessonDetails?.discipline ?? 'Неизвестная пара',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_formatDate(absenceDate)}\n'
                      'Тип: ${lessonDetails?.type ?? 'N/A'}',
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExcused ? 'Уважительная' : 'Пропуск',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExcused
                                ? Colors.grey.shade300
                                : Colors.red,
                          ),
                        ),
                        if (markedBy != null && markedBy.isNotEmpty)
                          Text(
                            'Отметил: $markedBy',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
