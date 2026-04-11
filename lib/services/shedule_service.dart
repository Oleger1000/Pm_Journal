// services/shedule_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Добавляем импорт
import '../models/shedule_item.dart';

class ScheduleService {
  // 🔹 КЭШ УРОВЕНЬ 1: В памяти (самый быстрый)
  static ScheduleResponse? _cachedResponse;

  // 🔹 КЭШ УРОВЕНЬ 2: Ключ для локального хранилища
  static const String _cacheKey = 'schedule_cache';

  static Future<ScheduleResponse> fetch() async {
    // 1. Проверяем кэш в памяти. Если данные есть, мгновенно возвращаем.
    if (_cachedResponse != null) {
      print("✅ Schedule from IN-MEMORY CACHE"); // Для отладки
      return _cachedResponse!;
    }

    // 2. Проверяем кэш в локальном хранилище (сохраняется между запусками).
    final prefs = await SharedPreferences.getInstance();
    final cachedDataString = prefs.getString(_cacheKey);

    if (cachedDataString != null) {
      print("✅ Schedule from LOCAL STORAGE CACHE"); // Для отладки
      final data = json.decode(cachedDataString);
      final response = _parseResponse(data);
      _cachedResponse = response; // Сохраняем в кэш памяти для будущих вызовов
      return response;
    }

    // 3. Если ни в одном кэше данных нет, делаем запрос в интернет.
    print("🔄 Schedule from NETWORK"); // Для отладки
    final res = await http.get(
      Uri.parse(
        'https://schedule.npi-tu.ru/api/v2/faculties/2/years/2/groups/%D0%9A%D0%9C%D0%A1%D0%B0/schedule',
      ),
    );

    // Сохраняем полученные данные в локальное хранилище для следующего запуска.
    if (res.statusCode == 200) {
      await prefs.setString(_cacheKey, res.body);
    }

    // Парсим ответ и возвращаем его
    final data = json.decode(res.body);
    final response = _parseResponse(data);
    _cachedResponse = response; // Также сохраняем в кэш памяти
    return response;
  }

  // Вспомогательный метод, чтобы не дублировать код парсинга
  static ScheduleResponse _parseResponse(Map<String, dynamic> data) {
    final classes = (data['classes'] as List)
        .map((e) => ScheduleItem.fromJson(e))
        .toList();
    final startDate = DateTime.parse(data['semester']['start']);
    return ScheduleResponse(classes: classes, startDate: startDate);
  }
}

class ScheduleResponse {
  final List<ScheduleItem> classes;
  final DateTime startDate;

  ScheduleResponse({required this.classes, required this.startDate});
}
