// services/student_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  // 🔹 КЭШ
  // Переменная для хранения списка студентов в памяти.
  // Знак '?' означает, что она может быть null (когда кэш пуст).
  List<Map<String, dynamic>>? _cachedStudents;

  Future<List<Map<String, dynamic>>> getStudents() async {
    // 1. Проверяем, есть ли данные в кэше.
    if (_cachedStudents != null) {
      // Если да - мгновенно возвращаем их, не делая запрос в базу.
      print("✅ Students from CACHE"); // Для отладки
      return _cachedStudents!;
    }

    // 2. Если кэш пуст, делаем запрос в Firebase.
    print("🔄 Students from FIREBASE"); // Для отладки
    final snapshot = await _db.collection('students').orderBy('name').get();

    final students = snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name']})
        .toList();

    // 3. Сохраняем полученные данные в кэш для будущих запросов.
    _cachedStudents = students;

    // 4. Возвращаем данные.
    return students;
  }

  Future<void> addStudent(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    await _db.collection('students').add({'name': cleanName});

    // 🔹 ВАЖНО: Очищаем кэш!
    // После добавления нового студента список изменился.
    // Мы должны сбросить кэш, чтобы при следующем вызове getStudents()
    // загрузился обновленный список из базы.
    _cachedStudents = null;
  }
}
