import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, excused }

class AttendanceService {
  final _db = FirebaseFirestore.instance;

  Future<void> markAttendance({
    required String studentId,
    required DateTime date,
    required int lesson,
    required AttendanceStatus status,
  }) async {
    // 1. Очищаем дату от часов и минут.
    // Нам важен только конкретный день, чтобы избежать ошибок с часовыми поясами.
    final pureDate = DateTime(date.year, date.month, date.day);

    // 2. Создаем УНИКАЛЬНЫЙ ID документа.
    // Формат: IDстудента_Год-Месяц-День_НомерПары
    final String docId =
        '${studentId}_${pureDate.year}-${pureDate.month}-${pureDate.day}_$lesson';

    // 3. Используем .doc(docId).set(...) вместо .add(...)
    // Если документа с таким docId нет — он создастся.
    // Если есть (вы нажали сохранить второй раз) — он просто перезапишется!
    await _db.collection('attendance').doc(docId).set({
      'studentId': studentId,
      'date': pureDate.toIso8601String(),
      'lesson': lesson,
      'status': status.name,
    });
  }

  Future<List<Map<String, dynamic>>> loadAttendance() async {
    final snapshot = await _db.collection('attendance').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
