import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getStudents() async {
    // УЛУЧШЕНИЕ 1: Добавлено .orderBy('name')
    // Теперь база данных сама отсортирует студентов по алфавиту!
    final snapshot = await _db.collection('students').orderBy('name').get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name']})
        .toList();
  }

  Future<void> addStudent(String name) async {
    // УЛУЧШЕНИЕ 2: Убираем случайные пробелы в начале и конце
    final cleanName = name.trim();

    // Если имя пустое - ничего не делаем (не сохраняем в базу)
    if (cleanName.isEmpty) return;

    await _db.collection('students').add({'name': cleanName});
  }
}
