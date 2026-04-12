// services/attendance_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shedule_item.dart';

enum AttendanceStatus { present, absent, excused }

class AttendanceService {
  final _db = FirebaseFirestore.instance;

  Future<void> updateAttendanceBatch({
    required Map<String, AttendanceStatus> statuses,
    required DateTime date,
    required int lesson,
    required String markedBy,
  }) async {
    final batch = _db.batch();
    final pureDate = DateTime(date.year, date.month, date.day);

    for (var entry in statuses.entries) {
      final studentId = entry.key;
      final status = entry.value;

      final String docId =
          '${studentId}_${pureDate.year}-${pureDate.month}-${pureDate.day}_$lesson';
      final docRef = _db.collection('attendance').doc(docId);

      if (status == AttendanceStatus.absent ||
          status == AttendanceStatus.excused) {
        // Если студент пропустил - создаем или обновляем запись
        batch.set(docRef, {
          'studentId': studentId,
          'date': pureDate.toIso8601String(),
          'lesson': lesson,
          'status': status.name,
          'markedBy': markedBy,
        });
      } else {
        batch.delete(docRef);
      }
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> loadAttendance() async {
    final snapshot = await _db.collection('attendance').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> markAttendance({
    required String studentId,
    required DateTime date,
    required int lesson,
    required AttendanceStatus status,
    required String markedBy,
  }) async {
    final pureDate = DateTime(date.year, date.month, date.day);
    final String docId =
        '${studentId}_${pureDate.year}-${pureDate.month}-${pureDate.day}_$lesson';

    await _db.collection('attendance').doc(docId).set({
      'studentId': studentId,
      'date': pureDate.toIso8601String(),
      'lesson': lesson,
      'status': status.name,
      'markedBy': markedBy,
    });
  }
}
